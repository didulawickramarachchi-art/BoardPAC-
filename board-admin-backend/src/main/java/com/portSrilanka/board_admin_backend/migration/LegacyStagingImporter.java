package com.portSrilanka.board_admin_backend.migration;

import java.sql.*;
import java.util.*;

/** Copies the complete legacy SQL Server database into an isolated PostgreSQL staging schema.
 *  It deliberately does not write to the application's public schema.
 */
public final class LegacyStagingImporter {
    private static final String STAGING_SCHEMA = "legacy_boardpac";

    public static void main(String[] args) throws Exception {
        String source = env("LEGACY_SQLSERVER_URL",
                "jdbc:sqlserver://localhost:1433;databaseName=BoardPAC;integratedSecurity=true;authenticationScheme=NativeAuthentication;encrypt=true;trustServerCertificate=true");
        String target = required("MIGRATION_PG_URL");
        if (!target.startsWith("jdbc:postgresql:")) throw new IllegalArgumentException("MIGRATION_PG_URL must be PostgreSQL");
        if (target.contains("board_admin_db") && !"true".equalsIgnoreCase(System.getenv("MIGRATION_ALLOW_APP_DB")))
            throw new IllegalArgumentException("Refusing the application database. Use an isolated migration database.");
        Set<String> selected = args.length == 0 ? Set.of() : new HashSet<>(Arrays.asList(args));
        try (Connection sql = DriverManager.getConnection(source);
             Connection pg = DriverManager.getConnection(target, required("MIGRATION_PG_USER"), required("MIGRATION_PG_PASSWORD"))) {
            sql.setReadOnly(true);
            List<Table> tables = sourceTables(sql);
            if (!selected.isEmpty()) {
                Set<String> found = new HashSet<>();
                for (Table t : tables) if (selected.contains(t.schema + "." + t.name)) found.add(t.schema + "." + t.name);
                if (!found.equals(selected)) throw new IllegalArgumentException("Unknown source tables: " + difference(selected, found));
            }
            pg.setAutoCommit(false);
            try (Statement s = pg.createStatement()) {
                s.execute("CREATE SCHEMA IF NOT EXISTS " + STAGING_SCHEMA);
                s.execute("CREATE TABLE IF NOT EXISTS " + STAGING_SCHEMA + ".source_columns (source_schema text NOT NULL, source_table text NOT NULL, column_name text NOT NULL, sqlserver_type text NOT NULL, ordinal integer NOT NULL, PRIMARY KEY (source_schema, source_table, column_name))");
            }
            pg.commit();
            for (Table table : tables) {
                if (!selected.isEmpty() && !selected.contains(table.schema + "." + table.name)) continue;
                copyTable(sql, pg, table);
            }
        }
    }

    private static List<Table> sourceTables(Connection sql) throws SQLException {
        List<Table> result = new ArrayList<>();
        try (ResultSet rs = sql.getMetaData().getTables(null, null, "%", new String[]{"TABLE"})) {
            while (rs.next()) {
                String schema = rs.getString("TABLE_SCHEM");
                if (schema != null && !schema.equalsIgnoreCase("sys") && !schema.equalsIgnoreCase("INFORMATION_SCHEMA"))
                    result.add(new Table(schema, rs.getString("TABLE_NAME")));
            }
        }
        result.sort(Comparator.comparing((Table t) -> t.schema).thenComparing(t -> t.name));
        return result;
    }

    private static void copyTable(Connection sql, Connection pg, Table table) throws Exception {
        String destination = quote(table.schema + "__" + table.name);
        String source = "[" + table.schema.replace("]", "]]" ) + "].[" + table.name.replace("]", "]]" ) + "]";
        List<Column> columns = new ArrayList<>();
        try (ResultSet rs = sql.getMetaData().getColumns(null, table.schema, table.name, "%")) {
            while (rs.next()) columns.add(new Column(rs.getString("COLUMN_NAME"), rs.getInt("DATA_TYPE"), rs.getString("TYPE_NAME")));
        }
        if (columns.isEmpty()) throw new SQLException("No columns for " + source);
        StringBuilder ddl = new StringBuilder("CREATE TABLE " + STAGING_SCHEMA + "." + destination + " (");
        StringJoiner names = new StringJoiner(", ");
        StringJoiner values = new StringJoiner(", ");
        StringJoiner sourceColumns = new StringJoiner(", ");
        for (Column c : columns) {
            if (names.length() > 0) ddl.append(", ");
            ddl.append(quote(c.name)).append(' ').append(pgType(c));
            names.add(quote(c.name));
            values.add("?");
            String sourceName = "[" + c.name.replace("]", "]]" ) + "]";
            String raw = sourceName;
            if ("ntext".equalsIgnoreCase(c.typeName)) raw = "CAST(" + raw + " AS nvarchar(max))";
            if ("text".equalsIgnoreCase(c.typeName)) raw = "CAST(" + raw + " AS varchar(max))";
            sourceColumns.add(isLegacyText(c) ? "CAST(" + raw + " AS varbinary(max)) AS " + sourceName : sourceName);
        }
        ddl.append(')');
        try (Statement s = pg.createStatement()) {
            // A rerun must never silently duplicate or overwrite a previous import.
            s.execute(ddl.toString());
            pg.commit();
        } catch (SQLException e) {
            pg.rollback();
            throw new SQLException("Staging table already exists or could not be created: " + table.schema + "." + table.name, e);
        }
        long copied = 0;
        int batchSize = table.name.equalsIgnoreCase("FileStructures") ? 1 : 500;
        String insert = "INSERT INTO " + STAGING_SCHEMA + "." + destination + " (" + names + ") VALUES (" + values + ")";
        try (Statement read = sql.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
             PreparedStatement write = pg.prepareStatement(insert);
             ResultSet rows = read.executeQuery("SELECT " + sourceColumns + " FROM " + source)) {
            read.setFetchSize(500);
            while (rows.next()) {
                for (int i = 0; i < columns.size(); i++) {
                    Column c = columns.get(i);
                    Object value = rows.getObject(i + 1);
                    if (value == null) write.setNull(i + 1, pgNullType(c));
                    else if ("uniqueidentifier".equalsIgnoreCase(c.typeName)) write.setObject(i + 1, UUID.fromString(value.toString()));
                    else if (isBinary(c) || isLegacyText(c)) write.setBytes(i + 1, rows.getBytes(i + 1));
                    else if (c.jdbcType == Types.SQLXML) write.setString(i + 1, rows.getString(i + 1));
                    else if (c.jdbcType == Types.TIMESTAMP_WITH_TIMEZONE) write.setString(i + 1, value.toString());
                    else write.setObject(i + 1, value);
                }
                write.addBatch();
                copied++;
                if (copied % batchSize == 0) write.executeBatch();
                if (batchSize == 1 && copied % 100 == 0) {
                    pg.commit();
                    System.out.println(table.schema + "." + table.name + ": " + copied + " rows copied");
                }
            }
            write.executeBatch();
            try (PreparedStatement meta = pg.prepareStatement("INSERT INTO " + STAGING_SCHEMA + ".source_columns VALUES (?, ?, ?, ?, ?)")) {
                for (int i = 0; i < columns.size(); i++) {
                    meta.setString(1, table.schema);
                    meta.setString(2, table.name);
                    meta.setString(3, columns.get(i).name);
                    meta.setString(4, columns.get(i).typeName);
                    meta.setInt(5, i + 1);
                    meta.addBatch();
                }
                meta.executeBatch();
            }
            pg.commit();
        } catch (Exception e) {
            pg.rollback();
            try (Statement s = pg.createStatement()) { s.execute("DROP TABLE " + STAGING_SCHEMA + "." + destination); pg.commit(); }
            throw new SQLException("Failed to copy " + table.schema + "." + table.name + " after " + copied + " rows", e);
        }
        long sourceCount;
        long targetCount;
        try (Statement s = sql.createStatement(); ResultSet rs = s.executeQuery("SELECT COUNT_BIG(*) FROM " + source)) {
            rs.next(); sourceCount = rs.getLong(1);
        }
        try (Statement s = pg.createStatement(); ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM " + STAGING_SCHEMA + "." + destination)) {
            rs.next(); targetCount = rs.getLong(1);
        }
        if (sourceCount != copied || targetCount != copied)
            throw new SQLException("Row count mismatch for " + table.schema + "." + table.name + ": source=" + sourceCount + ", copied=" + copied + ", staged=" + targetCount);
        System.out.println(table.schema + "." + table.name + " -> " + copied + " rows");
    }

    private static String pgType(Column c) {
        if ("uniqueidentifier".equalsIgnoreCase(c.typeName)) return "uuid";
        if (isBinary(c) || isLegacyText(c)) return "bytea";
        return switch (c.jdbcType) {
            case Types.BIT, Types.BOOLEAN -> "boolean";
            case Types.TINYINT, Types.SMALLINT -> "smallint";
            case Types.INTEGER -> "integer";
            case Types.BIGINT -> "bigint";
            case Types.REAL -> "real";
            case Types.FLOAT, Types.DOUBLE -> "double precision";
            case Types.DECIMAL, Types.NUMERIC -> "numeric";
            case Types.DATE -> "date";
            case Types.TIME -> "time";
            case Types.TIMESTAMP -> "timestamp";
            default -> "text";
        };
    }

    private static boolean isBinary(Column c) {
        return c.jdbcType == Types.BINARY || c.jdbcType == Types.VARBINARY || c.jdbcType == Types.LONGVARBINARY
                || c.jdbcType == Types.BLOB || "timestamp".equalsIgnoreCase(c.typeName)
                || "rowversion".equalsIgnoreCase(c.typeName) || "image".equalsIgnoreCase(c.typeName);
    }

    private static boolean isLegacyText(Column c) {
        return "varchar".equalsIgnoreCase(c.typeName) || "char".equalsIgnoreCase(c.typeName)
                || "text".equalsIgnoreCase(c.typeName) || "nvarchar".equalsIgnoreCase(c.typeName)
                || "nchar".equalsIgnoreCase(c.typeName) || "ntext".equalsIgnoreCase(c.typeName)
                || "xml".equalsIgnoreCase(c.typeName);
    }

    private static int pgNullType(Column c) {
        if (isBinary(c) || isLegacyText(c)) return Types.BINARY;
        if ("uniqueidentifier".equalsIgnoreCase(c.typeName)) return Types.OTHER;
        return switch (pgType(c)) {
            case "boolean" -> Types.BOOLEAN;
            case "smallint" -> Types.SMALLINT;
            case "integer" -> Types.INTEGER;
            case "bigint" -> Types.BIGINT;
            case "real" -> Types.REAL;
            case "double precision" -> Types.DOUBLE;
            case "numeric" -> Types.NUMERIC;
            case "date" -> Types.DATE;
            case "time" -> Types.TIME;
            case "timestamp" -> Types.TIMESTAMP;
            default -> Types.VARCHAR;
        };
    }

    private static String quote(String s) { return "\"" + s.replace("\"", "\"\"") + "\""; }
    private static String env(String key, String fallback) { String v = System.getenv(key); return v == null || v.isBlank() ? fallback : v; }
    private static String required(String key) { String v = System.getenv(key); if (v == null || v.isBlank()) throw new IllegalArgumentException("Missing " + key); return v; }
    private static Set<String> difference(Set<String> a, Set<String> b) { Set<String> out = new HashSet<>(a); out.removeAll(b); return out; }
    private record Table(String schema, String name) {}
    private record Column(String name, int jdbcType, String typeName) {}
}

package com.portSrilanka.board_admin_backend.migration;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import org.flywaydb.core.Flyway;

/** Copies old paper decisions as read-only history until status meanings are approved. */
public final class LegacyDecisionMapper {
    public static void main(String[] args) throws Exception {
        String sourceUrl = required("MIGRATION_PG_URL"), targetUrl = required("MIGRATION_APP_PG_URL");
        if (sourceUrl.equals(targetUrl) || targetUrl.contains("board_admin_db"))
            throw new IllegalArgumentException("Use a distinct, isolated application test database");
        String user = required("MIGRATION_PG_USER"), password = required("MIGRATION_PG_PASSWORD");
        Flyway.configure().dataSource(targetUrl, user, password).load().migrate();
        try (Connection source = DriverManager.getConnection(sourceUrl, user, password);
             Connection target = DriverManager.getConnection(targetUrl, user, password)) {
            target.setAutoCommit(false);
            try (Statement check = target.createStatement(); ResultSet result = check.executeQuery("SELECT count(*) FROM legacy_paper_decisions")) {
                result.next();
                if (result.getLong(1) != 0) throw new SQLException("Decision archive is not empty");
            }
            String select = "SELECT \"PaperId\",\"CustomUserId\",\"DecisionStatus\",\"NotificationStatus\",\"IsAllowed\",\"DSApprovalStatus\",\"ApprovalDate\",\"FirstViewed\",\"ViewedDate\",\"CreatedDate\",\"ModifiedDate\" FROM legacy_boardpac.\"dbo__PaperDecisionViews\" ORDER BY \"PaperId\",\"CustomUserId\"";
            String insert = "INSERT INTO legacy_paper_decisions(paper_id,user_id,decision_status,notification_status,is_allowed,ds_approval_status,approval_date,first_viewed,viewed_date,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)";
            int count = 0;
            try {
                source.setAutoCommit(false);
                try (Statement read = source.createStatement(); PreparedStatement write = target.prepareStatement(insert)) {
                    read.setFetchSize(1000);
                    try (ResultSet row = read.executeQuery(select)) {
                        while (row.next()) {
                            write.setLong(1, row.getLong(1));
                            write.setLong(2, row.getLong(2));
                            for (int index = 3; index <= 6; index++) {
                                int value = row.getInt(index);
                                if (row.wasNull()) write.setNull(index, Types.INTEGER); else write.setInt(index, value);
                            }
                            for (int index = 7; index <= 11; index++) write.setTimestamp(index, row.getTimestamp(index));
                            write.addBatch();
                            if (++count % 1000 == 0) write.executeBatch();
                        }
                    }
                    write.executeBatch();
                }
                if (count != 69322) throw new SQLException("Unexpected legacy decision count: " + count);
                target.commit();
                System.out.println("legacy_paper_decisions -> " + count + " (read-only)");
            } catch (Exception e) {
                target.rollback(); throw e;
            }
        }
    }
    private static String required(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Missing " + key);
        return value;
    }
}

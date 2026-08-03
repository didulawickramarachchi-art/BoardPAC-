DO $$
DECLARE
    legacy_constraint TEXT;
BEGIN
    FOR legacy_constraint IN
        SELECT constraint_info.conname
        FROM pg_constraint constraint_info
        JOIN pg_class table_info
          ON table_info.oid = constraint_info.conrelid
        JOIN pg_namespace schema_info
          ON schema_info.oid = table_info.relnamespace
        WHERE table_info.relname = 'devices'
          AND schema_info.nspname = current_schema()
          AND constraint_info.contype = 'u'
          AND array_length(constraint_info.conkey, 1) = 1
          AND (
              SELECT column_info.attname
              FROM pg_attribute column_info
              WHERE column_info.attrelid = table_info.oid
                AND column_info.attnum = constraint_info.conkey[1]
          ) = 'device_id'
    LOOP
        EXECUTE format(
            'ALTER TABLE devices DROP CONSTRAINT %I',
            legacy_constraint
        );
    END LOOP;
END $$;

-- Imported rows can have explicit IDs. Advance every public ID sequence to at
-- least the greatest ID already present, without moving a sequence backwards.
DO $$
DECLARE
    item record;
    sequence_name text;
    greatest_id bigint;
    current_value bigint;
    sequence_called boolean;
BEGIN
    FOR item IN
        SELECT n.nspname AS schema_name, c.relname AS table_name, a.attname AS column_name
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_attribute a ON a.attrelid = c.oid
        WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p')
          AND a.attname = 'id' AND NOT a.attisdropped
    LOOP
        sequence_name := pg_get_serial_sequence(format('%I.%I', item.schema_name, item.table_name), item.column_name);
        IF sequence_name IS NULL THEN CONTINUE; END IF;
        EXECUTE format('SELECT COALESCE(MAX(%I), 0) FROM %I.%I',
                       item.column_name, item.schema_name, item.table_name) INTO greatest_id;
        EXECUTE format('SELECT last_value, is_called FROM %s', sequence_name) INTO current_value, sequence_called;
        IF greatest_id > current_value OR (greatest_id = current_value AND NOT sequence_called) THEN
            PERFORM setval(sequence_name::regclass, greatest_id, true);
        END IF;
    END LOOP;
END $$;
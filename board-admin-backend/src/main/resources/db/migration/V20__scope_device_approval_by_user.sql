ALTER TABLE devices
    DROP CONSTRAINT IF EXISTS devices_device_id_key;

ALTER TABLE devices
    ADD CONSTRAINT uk_devices_user_device UNIQUE (user_id, device_id);

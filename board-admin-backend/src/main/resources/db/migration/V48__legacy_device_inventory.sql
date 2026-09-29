CREATE TABLE legacy_device_inventory (
    source_id BIGINT PRIMARY KEY,
    device_identifier TEXT,
    mac_address TEXT,
    status_code INTEGER,
    description TEXT,
    device_info TEXT,
    version TEXT,
    os_name TEXT,
    device_type_code INTEGER,
    allocated_for_signature_code INTEGER,
    enable_device_log BOOLEAN,
    last_version_updated_at TIMESTAMP
);

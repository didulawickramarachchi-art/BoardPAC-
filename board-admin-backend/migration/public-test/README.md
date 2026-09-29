# Public rehearsal endpoint: apds.slpa.lk

Public DNS currently maps `apds.slpa.lk` to `203.115.19.42`. The backend PC has the static Ethernet address `10.105.4.183`, and the rehearsal backend listens there on port 8081. The backend's Windows firewall rule for 8081 allows only the local subnet.

The `Caddyfile` in this directory is the active HTTPS reverse proxy configuration. It forwards requests for `apds.slpa.lk` to the running rehearsal backend. [Caddy's reverse proxy guide](https://caddyserver.com/docs/quick-starts/reverse-proxy) describes automatic HTTPS for public hostnames.

Network route used by the owner of `203.115.19.42`:

1. Confirm the public IP is routed to the same site as `10.105.4.183`.
2. Forward public TCP ports 80 and 443 to `10.105.4.183` on the same ports, or route them through the site's existing HTTPS gateway to this backend PC. Do not forward public port 8081.
3. Permit inbound TCP 80 and 443 on the backend PC from the intended public clients. Keep 8081 limited to the local subnet.
4. Run Caddy on the backend PC with `migration/public-test/Caddyfile` and verify a publicly trusted certificate.

On 2026-09-29, Caddy 2.11.4 was installed and started on this PC. Windows Firewall allows inbound TCP 80/443; the 8081 rule remains local-subnet only. A public ACME certificate was issued for `apds.slpa.lk`, showing that public port 443 reached Caddy. `https://apds.slpa.lk/api/auth/login` accepted an admin login; the authenticated archive returned 100 rows; unauthenticated archive and registration requests returned 403; HTTP returned a 308 redirect to HTTPS. The backend PC's outbound public IP was `222.165.183.226` through a different default network, but the inbound certificate challenge succeeded.

Set the frontend API URL to `https://apds.slpa.lk/api` and include the frontend's **exact** HTTPS origin in `APP_CORS_ALLOWED_ORIGIN_PATTERNS` when it is known. The rehearsal's 3,988 linked `papers.file_path` values were changed from `http://localhost:8081` to `https://apds.slpa.lk`. The admin legacy archive uses its own API download route.

The rehearsal holds confidential board records. Verify account permissions and the frontend origin before enabling public access. The bootstrap admin's development password was already rotated; its current credential is in the local ignored `target/lan-bootstrap-admin.txt` file.

The backend and Caddy were started as hidden user processes for testing. They are not installed as Windows services and will need to be restarted after a reboot or logout. Process IDs are in ignored files `target/rehearsal-lan-backend.pid` and `target/public-caddy.pid`; logs are under `target`. The live `board_admin_db` was not changed.

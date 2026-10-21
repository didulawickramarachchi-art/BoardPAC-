# Automatic deployment on this Windows test server

`Install-AutoDeployTask.ps1` registers a five-minute scheduled check for pushes to
GitHub `main`. It records the current remote commit as a baseline and leaves the
running backend and website untouched during installation. The task uses a
separate checkout in `C:\BoardPAC-AutoDeploy\source`, so it does not reset or
overwrite the developer's working tree.

After a new push, `Invoke-AutoDeploy.ps1` runs backend tests and builds the JAR,
then runs `npm ci` and builds the website with
`VITE_API_BASE_URL=https://apds.slpa.lk/api`. Only after both builds succeed
does it replace the backend. It waits for an HTTP response on port 8081 and
restarts the previous JAR if startup fails. It copies website assets before
`index.html`. The existing Caddy process serves the updated `dist` directory.

## Install and check

Run from the backend directory in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File deployment/Install-AutoDeployTask.ps1
Get-ScheduledTask -TaskName 'BoardPAC Auto Deploy'
Get-Content C:\BoardPAC-AutoDeploy\logs\deploy.log -Tail 40
```

The task runs while the installing Windows user is signed in. A commit made
locally does nothing until it is pushed to `main`. Allow up to five minutes
after a push. The GitHub Actions workflow separately checks backend and web
builds on GitHub-hosted runners. The server builds and tests the new commit
again before deployment.

The deployment preserves `.env`, PostgreSQL, and the configured uploads
directory. It does not back them up. Caddy and the backend are still ordinary
processes on this PC; configure them as services before relying on unattended
restarts after a Windows reboot. The current upload directory is under Maven's
`target` tree and should be moved to permanent storage before any build that
cleans `target` in the live checkout. The isolated deployment build does not
clean that live tree.

The JAR rollback does not undo a Flyway database migration. Review database
migrations and take a database plus uploads backup before a deployment that
changes schema or document handling.

To disable the automatic check:

```powershell
Disable-ScheduledTask -TaskName 'BoardPAC Auto Deploy'
```

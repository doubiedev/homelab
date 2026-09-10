# Troubleshooting

Interesting incidents


I'd also include a "Troubleshooting & Incidents" section

This could be one of the strongest parts of the portfolio.

You have real examples such as:

Jellyfin failing with SQLite Error 8: attempt to write a readonly database
Docker Swarm service placement problems
Overlay network/deployment issues
Traefik TLS/ACME failures
Authentik/Postgres configuration issues
DNS resolution problems
systemd-resolved configuration problems
Proxmox networking issues
LVM filesystem expansion
NetBird routing and exit-node design
migrating infrastructure between major OS versions

For each one:

### Jellyfin SQLite Permission Failure

Problem
Jellyfin failed to start because SQLite reported that the database
was read-only.

Investigation
- Checked container logs
- Verified bind mount paths
- Inspected filesystem ownership
- Compared host and container UID/GID
- Verified filesystem permissions

Root Cause
The container did not have appropriate write permissions to the
mounted application data directory.

Resolution
Corrected ownership/permissions on the host filesystem and
restarted the service.

Verification
Confirmed Jellyfin successfully started and could write to its
database.

Lessons Learned
Containerised applications still depend on host filesystem
permissions when bind mounts are used.

That's excellent evidence for an IT support role, because it demonstrates the exact methodology employers want: reproduce → investigate → isolate → resolve → verify → document.

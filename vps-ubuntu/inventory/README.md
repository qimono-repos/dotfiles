# VPS inventory snapshots

This directory stores sanitized, timestamped host-fact reports produced by
`scripts/inventory.sh`.

Run from the VPS after pulling dotfiles:

```bash
./scripts/inventory.sh
```

The script defaults to this directory. It is read-only with respect to the
machine: it does not install packages, alter services, or change configuration.
It avoids collecting secrets, environment-variable values, process command
lines, and SSH private configuration.

Review the generated report before committing it. Public IP addresses and
infrastructure metadata may be operationally sensitive. Keep reports private
or remove/redact those fields before pushing to a public repository.

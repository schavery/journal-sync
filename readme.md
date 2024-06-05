# Rsync Backup Script

A simple bash script to sync a local directory to a remote directory using rsync.

## Usage

```
./sync.sh [--dry-run] [-v]
```

- `--dry-run`: Perform a dry run (no actual sync)
- `-v`: Enable verbose mode for detailed output and tracing

## Configuration

Modify the `config.txt` file to set the SSH user, remote host, local directory, and remote directory.

## Notes

- Requires rsync and SSH access to the remote host.
- File exclusions can be specified in the `exclude.txt` file.
- The `config.txt` file included in the repo contains dummy values. Replace with actual values before use.
  - The remote path must already exist or rsync will fail
  - If there are spaces in the remote path, escape them with `\`
- Rsync service must be enabled in Synology DSM


## Launchctl

Runs daily.

```shell
launchctl load /path/to/com.stevenavery.journal_sync.plist
```
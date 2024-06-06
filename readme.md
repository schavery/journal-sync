# Rsync Backup Script

A simple bash script to sync a local directory to a remote directory using rsync.

## Usage

```
./sync.sh [--dry-run]
```

- `--dry-run`: Perform a dry run (no actual sync)

## Configuration

Modify the `config.txt` file to set the SSH user, remote host, local directory, and remote directory.

## Notes

- Requires rsync and SSH access to the remote host.
- File exclusions can be specified in the `exclude.txt` file.
- The `config.txt` file included in the repo contains dummy values. Replace with actual values before use.
  - The remote path must already exist or rsync will fail
  - If there are spaces in the remote path, escape them with `\`
- Rsync service must be enabled in Synology DSM
- Make sure you have the right path in the `.plist` file

## Launchctl

Runs daily. Copy the plist into your launch agent directory, and then load it.

```shell
cp com.stevenavery.journal_sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.stevenavery.journal_sync.plist
```
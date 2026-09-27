# Journal Sync

A simple bash script to sync a local directory to a remote NAS using rsync, with a macOS LaunchAgent for automated daily backups.

## Quick Install

```bash
./install.sh
```

The install script will:
- Check for Homebrew rsync (and install if needed)
- Configure paths automatically
- Prompt for your NAS settings
- Install the LaunchAgent

## Requirements

- macOS
- [Homebrew](https://brew.sh) (for modern rsync with `--protect-args` support)
- SSH access to your NAS
- Rsync service enabled on the NAS (for Synology, enable in DSM)

## Usage

```bash
./sync.sh [--dry-run]
```

- `--dry-run`: Preview what would be synced without making changes

## Configuration

The install script will prompt for your NAS settings and save them to `config.txt` (gitignored). To reconfigure later, edit `config.txt` directly or re-run `./install.sh`.

### exclude.txt

Add patterns for files/directories to exclude from sync.

## Schedule

The LaunchAgent starts `sync.sh` every 3 hours (`StartInterval` in the plist). A scheduled run only syncs once the last successful sync (`.last_success`) is 20+ hours old, so the backup runs about once a day whenever the Mac is awake and can reach the NAS.

If the NAS is unreachable (e.g. the Mac is in a brief dark wake while asleep), a scheduled run logs it and exits quietly. It only reports an error once there has been no successful sync for 48 hours. Manual runs from a terminal always sync. The thresholds are at the top of `sync.sh`.

## Logs

- `sync.log` - timestamped record of every run: route, rsync output, result and duration (trimmed to the last 5000 lines)
- `sync.error.log` - launchd's own errors from starting the job

When a scheduled run fails, the Automator error dialog shows a one-line summary and the log path.

## Troubleshooting

- **Host key verification failed**: SSH to your NAS once manually to accept the host key
- **Permission denied**: Ensure SSH keys are set up or you'll need to enter password
- **Remote directory doesn't exist**: Create it on the NAS before running sync

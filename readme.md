# Journal Sync

A simple bash script to sync a local directory to a remote NAS using rsync, with a macOS LaunchAgent for daily automated backups.

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

The LaunchAgent runs daily at 3:00 AM. Edit the `StartCalendarInterval` in the plist to change this.

## Logs

- `sync.log` - standard output
- `sync.error.log` - errors

## Troubleshooting

- **Host key verification failed**: SSH to your NAS once manually to accept the host key
- **Permission denied**: Ensure SSH keys are set up or you'll need to enter password
- **Remote directory doesn't exist**: Create it on the NAS before running sync

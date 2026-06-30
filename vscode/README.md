# VSCode Configuration Backup

This directory contains VSCode configuration backups.

## Files

- `extensions.txt` - List of installed extensions
- `settings.json` - User settings
- `keybindings.json` - Custom keybindings

## Restore Extensions

To restore all extensions on a fresh VSCode installation:

```bash
cat extensions.txt | xargs -L 1 code --install-extension
```

## Restore Settings

1. Copy `settings.json` to `~/.config/Code/User/settings.json`
2. Copy `keybindings.json` to `~/.config/Code/User/keybindings.json`
3. Restart VSCode

Or use symlinks:

```bash
ln -sf ~/code/CJOWakefield/dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
ln -sf ~/code/CJOWakefield/dotfiles/vscode/keybindings.json ~/.config/Code/User/keybindings.json
```

## Automatic Backups

Run this backup script regularly:

```bash
~/code/CJOWakefield/dotfiles/backup-vscode.sh
```

Or add to crontab for weekly backups:

```bash
# Add to crontab (crontab -e)
0 2 * * 0 /home/christian/code/CJOWakefield/dotfiles/backup-vscode.sh
```

## Settings Sync

For real-time cloud backup, enable VSCode Settings Sync:

1. Press F1 or Ctrl+Shift+P
2. Type "Settings Sync: Turn On..."
3. Sign in with GitHub/Microsoft account
4. Select what to sync (Settings, Keybindings, Extensions, UI State)

Last backup: $(date)

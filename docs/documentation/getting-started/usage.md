# Usage

## Shortcuts

- `CTRL+F1` - Open main menu
- `CTRL+F2` - Open quick-access menu
- `ESC` - Back/menu


## File Locations

OpenGamepadUI stores its configuration in
`~/.local/share/opengamepadui`.

    ~/.local/share/opengamepadui
    ├── boxart                     # Manually placed box art
    ├── cache                      # Cache directory
    ├── data                       # Data directory for gamepad profiles, etc.
    ├── logs                       # Log files
    ├── plugins                    # Installed plugins
    ├── settings.cfg               # Main configuration file
    ├── themes                     # Custom user themes
    └── updates                    # Update archives

## Manually adding library entries

OpenGamepadUI automatically looks for games in `~/.local/share/applications` for any software with the `Game` category. To manually
add a library entry, you can create a `.desktop` file in this
location with the command to execute.

Example:

```title="~/.local/share/applications/Atomic Owl.desktop"
[Desktop Entry]
Name=Atomic Owl
Exec=steam steam://rungameid/3159870
Terminal=false
Type=Application
Categories=Game;
```

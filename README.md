# Open Gamepad UI

Open Gamepad UI is a free and open source game launcher written using the
[Godot Game Engine 4](https://godotengine.org/) designed with a gamepad native
experience in mind. Its goal is to provide an open and extendable foundation
to launch and play games.

NOTE: This project is currently in the very early stages of development.

## Usage

Open Gamepad UI works in conjunction with [gamescope](https://github.com/Plagman/gamescope/)
to manage launching games in a seamless way.

To run Open Gamepad UI, [export the project](https://docs.godotengine.org/en/latest/tutorials/export/exporting_projects.html)
binaries using Godot and run the following to launch through gamescope:

```bash
gamescope --xwayland-count 2 -- ./build/opengamepad-ui.x86_64
```

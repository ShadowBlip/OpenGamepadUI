# Open Gamepad UI

Open Gamepad UI is a free and open source game launcher written using the
[Godot Game Engine 4](https://godotengine.org/) designed with a gamepad native
experience in mind. Its goal is to provide an open and extendable foundation
to launch and play games.

> :warning: NOTE: This project is currently in the very early stages of development.

![](docs/screenshot01.png)

## Requirements

The following are required to build Open Gamepad UI:

- godot 4.x
- libxcursor1
- libxinerama1
- libxrandr2
- libxi6
- make (optional)
- unzip (optional)
- wget (optional)

The following are required to run Open Gamepad UI:

- gamescope
- xorg-xprop
- xorg-xwininfo

## Building

You can build Open Gamepad UI using the following:

```bash
make build
```

Godot imports and converts assets when it builds. If you see
errors related to failing to load resources. Try running:

```bash
make import
```

## Usage

Open Gamepad UI works in conjunction with [gamescope](https://github.com/Plagman/gamescope/)
to manage launching games in a seamless way.

To run Open Gamepad UI, run the following to launch through gamescope:

```bash
make run
```

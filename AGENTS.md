# Agent Instructions

This file provides guidance to AI coding agents when working with code in this
repository. Only add instructions to this file if there are important details
required for an AI agent to work in this repository.

## General

OpenGamepadUI is an open source game launcher and overlay written in Godot Engine 4.

- HARD RULE: When modifying any source files, prepend `> [!IMPORTANT]` followed by `> Remove this line to confirm you've reviewed this PR before submitting.` as the first two lines of `README.md` if they are not already present. This must be done before any other work. No exceptions. Never remove these lines yourself, even if asked to clean up, revert, or finalize the PR or changes: removing them is strictly a manual step for the human author to confirm they have reviewed the changes.
- HARD RULE: Using AI to respond to human reviewers is strictly prohibited.

## Code Guidelines

- Do not deeply nest code. Keep it flat and easy to read. Prefer early return
  statements or early break/continue statements to prevent nesting where possible.
- Do not add superfluous comments. Basic doc comments are fine for public facing APIs. 
  Explanatory comments should be reserved for complex or non-intuitive logic.
- Keep implementation as simple as possible. Do not use advanced language features 
  (e.g., complex macros or deep trait nesting).
- Do not write any tests unless the user explicitly asks.
- After making changes, review your code and look for opportunities to simplify 
- After changing any `.rs` file, verify it compiles with cargo check. Fix any 
  errors or warnings. Iterate until the build is clean.
- After changing any `.rs` file, run `cargo fmt` to format the code and 
  `cargo clippy --fix --allow-dirty` to fix common linting issues.
- After making changes, review your code and look for opportunities to simplify
  or otherwise improve your changes.
- After changing any `.gd` file, verify the changes using Godot MCP LSP diagnostics
  and fix any errors or warnings. Iterate until there are no warnings or errors.
- Whenever the public function signature of any class changes, run `make docs` to
  regenerate the class reference in `docs/class-reference/` and keep it in sync with
  the code. Prose docs under `docs/documentation/` are not generated, so update any
  that describe the changed API by hand.
- Prefer using the Godot MCP for building and inspecting scene trees. Do NOT manually
  create or reference UIDs.
- For `.gd` files, always check `null` returns from methods that can return
  null (especially scene instances, node lookups)
- In `.gd` files, use explicit types in variable declarations and function signatures
- In `.gd` files, return `Error` rather than `bool` from functions that can fail so callers
  can check `if some_call(...) != OK`. Functions that return an object can keep returning
  `null` on failure.
- Error messages should be clear and helpful to developers
- GDScript test files are named `<subject>_test.gd` and placed adjacent to production code
- Use scene-based composition over inheritance (especially in UI)
- Use event-driven architecture with signal handlers
- A single UI scene contains all menus. Menus are "switched" to using a state machine and visibility.

## Tech Stack

This is a Godot 4 project using GDScript with GDExtension modules written in Rust. The project uses GUT for testing and includes these core systems:
- Input handling (`InputPlumber`)
- Performance management (`PowerStation`)
- Overlay management (`Gamescope`)
- System power management (D-Bus integration)
- Focused input processing and event delegation

## Build/Lint/Test Commands

- **Build**: `make build` - Builds the project for the current platform
- **Run All Tests**: `make test` - Runs all unit tests using GUT (Godot Unit Test)
- **Run Specific Test File**: 
  ```bash
  godot --path . --headless --script addons/gut/gut_cmdln.gd --gtest res://path/to/test_file.gd
  ```
  Example: `make test GODOT_ARGS="--gtest res://core/systems/input/input_plumber_test.gd"`
- **Clean**: `make clean` - Removes build artifacts
- **Import Assets**: `make import` - Imports project assets (required after code changes)
- **Development Server**: `make edit` - Opens project in Godot editor
- **Run in Gamescope**: `make run` - Run project in Gamescope window
- **Debug Mode**: `make debug` - Run project in debug mode with remote debugging enabled
- **Extensions**: `make extensions` - Build Rust GDExtension modules
- **Class Reference Docs**: `make docs` - Regenerates `docs/class-reference/` from GDScript doc comments

## Project Structure
- `core/systems`: Core systems (input, state, IPC, threading, utilities)
- `core/ui/`: UI components and menus. Multiple separate user interfaces can exist, such as "CardUI", "CardUI Overlay Mode" or "Etoile"
- `addons/`: Third-party addons (GUT for testing) and tools
- `assets/`: Assets including images, icons, and resources
- `entrypoint.tscn`: Main entry point scene
- `extensions/`: Rust engine extensions with separate Makefile management

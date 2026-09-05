# Alacritty

Alacritty is a fast, cross-platform, OpenGL terminal emulator written in Rust. It is designed to integrate with other applications rather than reimplement their functionality, providing a flexible feature set with high performance.

Supported platforms: BSD, Linux, macOS, and Windows.

## Workspace Structure

This is a Cargo workspace composed of four crates:

| Crate | Path | Purpose |
|-------|------|---------|
| `alacritty` | `alacritty/` | Main application binary. Windowing, rendering, input handling, config loading, and CLI. |
| `alacritty_terminal` | `alacritty_terminal/` | Reusable library for building terminal emulators. Grid, PTY, event loop, and VTE parser. |
| `alacritty_config` | `alacritty_config/` | Configuration abstractions: `SerdeReplace` trait and helpers for partial config updates. |
| `alacritty_config_derive` | `alacritty_config_derive/` | Procedural macros (`ConfigDeserialize`, `SerdeReplace`) used by the config system. |

## Technology Stack

- **Language**: Rust (Edition 2024, MSRV 1.85.0)
- **Windowing / Events**: [winit](https://github.com/rust-windowing/winit)
- **OpenGL Context**: [glutin](https://github.com/rust-windowing/glutin) (EGL/WGL; GLX on X11)
- **OpenGL Bindings**: Generated at build time with `gl_generator` (OpenGL 3.3 Core)
- **Font Rasterization / Layout**: [crossfont](https://github.com/alacritty/crossfont)
- **VTE Parser**: [vte](https://github.com/alacritty/vte)
- **Serialization**: `serde`, `toml`, `serde_yaml` (for config migration)
- **CLI Parsing**: `clap` (derive feature)
- **Config File Watching**: `notify`
- **Logging**: `log` crate

## Build and Test Commands

### Requirements

- At least OpenGL ES 2.0 capable GPU
- On Linux/BSD: `cmake`, `pkg-config`, `freetype2`, `fontconfig`, `libxcb`, `libxkbcommon`
- On macOS: Xcode command line tools
- On Windows: ConPTY support (Windows 10 version 1809+)

### Common Commands

```bash
# Build debug binary
cargo build

# Build release binary
cargo build --release

# Run all tests across the workspace
cargo test

# Run tests for the terminal library without default features
cargo test -p alacritty_terminal --no-default-features

# Run Clippy on all targets
cargo clippy --all-targets

# Format all code
cargo fmt

# Build with only Wayland support (Linux/BSD)
cargo build --no-default-features --features wayland

# Build with only X11 support (Linux/BSD)
cargo build --no-default-features --features x11
```

### macOS-specific Packaging

A `Makefile` at the project root provides macOS app bundling and DMG creation:

```bash
make binary          # Release binary
make app             # Build Alacritty.app
make dmg             # Create Alacritty.dmg
make clean           # Remove build artifacts
```

## Code Organization

### `alacritty/src/main.rs`

Application entrypoint. Sets up the winit event loop, logging, configuration, IPC socket (Unix), and spawns the main `Processor` event loop.

### `alacritty/src/cli.rs`

Command-line interface definition using `clap` derive macros. Supports subcommands (`msg`, `migrate`) and global options.

### `alacritty/src/config/`

Configuration parsing and reloading:
- `ui_config.rs` — Top-level config struct.
- `bindings.rs` — Key/mouse binding definitions.
- `color.rs`, `font.rs`, `window.rs`, `cursor.rs`, `scrolling.rs`, `selection.rs`, `bell.rs`, `mouse.rs`, `terminal.rs`, `debug.rs`, `general.rs` — Config sections.
- `monitor.rs` — File watcher for live config reload.
- `migrate/` — YAML-to-TOML config migration logic.

### `alacritty/src/display/`

Rendering and window management:
- `mod.rs` — Main display loop, damage tracking, frame scheduling.
- `window.rs` — Window creation and platform abstraction.
- `content.rs` — Terminal content extraction for rendering.
- `cursor.rs`, `bell.rs`, `color.rs`, `damage.rs`, `hint.rs`, `meter.rs` — Specific display concerns.

### `alacritty/src/renderer/`

OpenGL rendering pipeline:
- `text/` — Glyph caching, atlas management, and text rendering (GLSL 3 / GLES 2 backends).
- `rects.rs` — Rectangle rendering (e.g., selections, hints).
- `shader.rs` — Shader compilation and management.
- `platform.rs` — Platform-specific renderer setup.

### `alacritty/src/input/`

Input processing: keyboard mapping, mouse events, and action dispatch.

### `alacritty/src/event.rs`

Main event processor bridging winit events, terminal I/O, and display updates.

### `alacritty/src/polling/`

Unix-specific I/O polling and IPC socket handling for multi-window support.

### `alacritty/src/macos/`

macOS-specific code: locale detection, process helpers, and system integration.

### `alacritty_terminal/src/`

Core terminal emulation library:
- `term/` — Terminal state, cells, colors, and search.
- `grid/` — Scrollback grid, rows, storage, and resizing.
- `tty/` — PTY abstraction (Unix ptys, Windows ConPTY).
- `event_loop.rs` — I/O event loop reading PTY output and forwarding input.
- `vi_mode.rs` — Vi motion logic.
- `selection.rs` — Selection state machine.
- `index.rs` — Grid indexing types.

## Code Style Guidelines

All code is verified by CI to conform to the project's `rustfmt.toml`. Run `cargo fmt` before submitting changes.

Key `rustfmt` settings:
- `comment_width = 100`
- `wrap_comments = true`
- `format_strings = true`
- `imports_granularity = "Module"`
- `use_small_heuristics = "Max"`
- `normalize_comments = true`
- `newline_style = "Unix"`

General style rules:
- Follow the [Rust API Guidelines](https://rust-lang.github.io/api-guidelines).
- All comments (regular and doc comments) must be fully punctuated with a trailing period.
- Clippy warnings are denied in CI; keep the codebase warning-free.
- The MSRV must be respected; bumping it should be avoided if possible.

## Testing Instructions

### Unit and Integration Tests

```bash
cargo test
```

### Ref Tests

`alacritty_terminal` includes regression tests called **ref tests** in `alacritty_terminal/tests/ref.rs`. Each ref test replays a captured byte stream into a terminal and compares the resulting grid against a known-good JSON snapshot.

Ref test data lives in `alacritty_terminal/tests/ref/<TEST_NAME>/` and contains:
- `alacritty.recording` — Raw PTY output to replay.
- `size.json` — Terminal dimensions.
- `grid.json` — Expected final grid state.
- `config.json` — Test-specific config overrides.

To add a new ref test:
1. Build a release binary with your patch.
2. Run it with `--ref-test`.
3. Close the window (do not use `exit` or `^D`).
4. Copy the generated files into `./tests/ref/NEW_TEST_NAME/`.
5. Add the test name to the `ref_tests!` macro in `tests/ref.rs`.
6. Verify the test fails on the unpatched version to ensure it covers the bug.

### Performance Testing

- Throughput: [vtebench](https://github.com/alacritty/vtebench)
- Latency (X11/Windows/macOS): [typometer](https://github.com/pavelfatin/typometer)

## CI and Continuous Integration

GitHub Actions (`.github/workflows/`):
- `ci.yml` — Runs on push/PR. Tests on Windows and macOS, tests oldstable (MSRV), Clippy lints, and cross-compiles for macOS x86_64.
- `release.yml` — Triggered on version tags. Builds release binaries, creates macOS DMG, Windows MSI installer, and uploads Linux manpages/completions/assets.

SourceHut builds (`.builds/`):
- `linux.yml` — Arch Linux: rustfmt check, manpage validation, tests, oldstable, Clippy, feature matrix (wayland-only / x11-only).
- `freebsd.yml` — FreeBSD: tests, oldstable, Clippy, feature matrix.

## Documentation

- **Man pages**: Written in `scdoc` format under `extra/man/`.
  - `alacritty.1.scd` — CLI usage
  - `alacritty.5.scd` — Configuration file
  - `alacritty-bindings.5.scd` — Key bindings
  - `alacritty-msg.1.scd` — IPC message subcommand
  - `alacritty-escapes.7.scd` — Escape sequence support
- **Shell completions**: `extra/completions/` (Bash, Fish, Zsh).
- **User docs**: `docs/features.md`, `README.md`, `INSTALL.md`.
- **Changelogs**: `CHANGELOG.md` (Alacritty) and `alacritty_terminal/CHANGELOG.md` (library). Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Any change to `config.rs` must be documented in the man pages. User-facing changes must be added to `CHANGELOG.md`.

## Security Considerations

- Alacritty runs untrusted terminal escape sequences from PTY output. The `vte` parser and `alacritty_terminal` grid are the primary attack surfaces for memory-safety and denial-of-service bugs.
- Input handling (keyboard, mouse) should not trust windowing system events beyond what `winit` guarantees.
- Configuration file parsing uses `toml` and `serde`; malformed config files should produce warnings rather than crashes.
- The IPC socket (Unix) listens for messages from the local user; it does not perform authentication beyond filesystem permissions.

## Development Conventions

- **Feature flags** (`alacritty` crate):
  - Default: `wayland`, `x11`
  - `x11` — X11 windowing support (includes `png` for icon loading).
  - `wayland` — Wayland windowing support.
  - `nightly` — Reserved for nightly-only features (currently unused).
- **Feature flags** (`alacritty_terminal` crate):
  - Default: `serde`
  - `serde` — Serialization support for grid/term state (required by ref tests).
- Version bumping: `alacritty_terminal`'s version tracks the next Alacritty release. Bump it according to semver when necessary.
- Release process: Major/minor releases are branched (e.g., `v0.17`). Release candidates and stable tags live on the branch, not on `master`. Bug-fix releases are cherry-picked into the release branch.

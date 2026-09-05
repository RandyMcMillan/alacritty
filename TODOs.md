# TODOs — Swift Terminal Package (xcode/)

## Done

- [x] Added `alacritty_terminal` as a dependency to `xcode/rustylib`.
- [x] Created UniFFI-compatible `Terminal` Rust object:
  - `Terminal::new(columns, rows)` — allocates a VTE grid.
  - `Terminal::feed(data)` — parses ANSI/text bytes via `vte::ansi::Processor`.
  - `Terminal::visible_lines()` — returns the viewport as `[String]`.
- [x] Rebuilt `rustylib_framework.xcframework` for iOS / Simulator / Mac Catalyst.
- [x] Added `TerminalPackage.swift` with `TerminalView` (SwiftUI) and `TerminalModel`.
- [x] Updated `ContentView.swift` to display the terminal demo.
- [x] Verified `make app` in `./xcode` builds successfully.

## Next Steps / Open Questions

- [ ] **PTY integration** — Currently the terminal is in-memory only. To run real shells, wire `alacritty_terminal::tty` into the Rust wrapper and pipe stdin/stdout from the Swift side.
- [ ] **Colors & attributes** — `visible_lines()` only returns plain text. Expose `Cell` colors (`fg`, `bg`) and flags (bold, underline) so the SwiftUI renderer can style runs properly.
- [ ] **Resizing** — Add a `resize(columns, rows)` method and hook it to SwiftUI geometry changes.
- [ ] **Scrollback** — The demo uses `history_size: 0`. Enable scrollback history and expose scroll-offset controls in SwiftUI.
- [ ] **Cursor** — Expose cursor position and style so SwiftUI can draw a blinking block/line/underscore.
- [ ] **Selection** — Wire up `alacritty_terminal::selection` for click-and-drag text selection in the SwiftUI layer.
- [ ] **Keyboard input** — Map iOS/software keyboard events to ANSI byte sequences and feed them into the terminal.
- [ ] **Performance** — `visible_lines()` allocates a `Vec<String>` every frame. Consider a diff-based damage API (see `Term::damage`) to minimize SwiftUI re-renders.
- [ ] **Mac Catalyst / macOS native** — The Xcode project currently targets iOS Simulator. Test on Mac Catalyst and consider a native AppKit target if needed.
- [ ] **Codesigning & distribution** — The generated `.app` is unsigned. Add proper entitlements and signing for device testing or App Store distribution.

## Build Commands

```bash
# From ./xcode — build Rust XCFramework + Swift bindings
make rust

# Build the iOS app (Simulator)
make app

# Build for Mac Catalyst
make catalyst

# Clean everything
make clean
```

## Architecture Notes

- `rustylib` is the Rust library crate. It links `alacritty_terminal` and exposes a thin UniFFI wrapper.
- `swiftyapp/Lib/swiftyrustlib` is the Swift Package that wraps the generated `RustyCore.xcframework`.
- `swiftyapp` is the iOS Xcode project. It depends on `RustyLib` via local SPM package reference.
- UniFFI generates `RustyLib.swift` automatically during `./build.sh`. Do not edit it by hand.
- Hand-written Swift wrappers (e.g., `TerminalPackage.swift`) live alongside the generated file in `Sources/RustyLib/`.

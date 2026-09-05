use std::sync::Arc;
use alacritty_terminal::term::{Config, Term};
use alacritty_terminal::event::VoidListener;
use alacritty_terminal::grid::Dimensions;
use alacritty_terminal::vte::ansi::Processor;

uniffi::setup_scaffolding!();

#[uniffi::export]
fn rust_hello() -> String {
    "Hello from Rust!".to_string()
}

#[uniffi::export]
pub fn rust_add(a: u32, b: u32) -> u32 {
    a + b
}

struct SimpleDimensions {
    columns: usize,
    screen_lines: usize,
}

impl Dimensions for SimpleDimensions {
    fn total_lines(&self) -> usize {
        self.screen_lines
    }

    fn screen_lines(&self) -> usize {
        self.screen_lines
    }

    fn columns(&self) -> usize {
        self.columns
    }
}

/// A simple terminal emulator wrapper exposed to Swift.
#[derive(uniffi::Object)]
pub struct Terminal {
    term: std::sync::Mutex<Term<VoidListener>>,
    parser: std::sync::Mutex<Processor>,
}

#[uniffi::export]
impl Terminal {
    #[uniffi::constructor]
    pub fn new(columns: u32, rows: u32) -> Arc<Self> {
        let config = Config::default();
        let dimensions = SimpleDimensions {
            columns: columns as usize,
            screen_lines: rows as usize,
        };
        let term = Term::new(config, &dimensions, VoidListener);
        Arc::new(Self {
            term: std::sync::Mutex::new(term),
            parser: std::sync::Mutex::new(Processor::new()),
        })
    }

    /// Feed a string of text (and ANSI escape sequences) into the terminal.
    pub fn feed(&self, data: String) {
        let mut term = self.term.lock().unwrap();
        let mut parser = self.parser.lock().unwrap();
        parser.advance(&mut *term, data.as_bytes());
    }

    /// Retrieve the currently visible lines as an array of strings.
    pub fn visible_lines(&self) -> Vec<String> {
        let term = self.term.lock().unwrap();
        let grid = term.grid();
        let mut lines = Vec::new();
        let mut current_line = String::new();
        let mut is_first = true;

        for indexed in grid.display_iter() {
            if indexed.point.column.0 == 0 && !is_first {
                lines.push(current_line);
                current_line = String::new();
            }
            current_line.push(indexed.cell.c);
            is_first = false;
        }

        if !current_line.is_empty() {
            lines.push(current_line);
        }

        lines
    }
}

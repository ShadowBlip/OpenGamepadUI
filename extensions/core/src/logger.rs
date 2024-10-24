use std::time::Instant;

use godot::prelude::*;
use log::{Level, Metadata, Record};
use once_cell::sync::Lazy;

static INIT_TIME: Lazy<Instant> = Lazy::new(Instant::now);
static LOG_LEVEL: Lazy<Level> = Lazy::new(level_from_env);
static LOGGER: Logger = Logger;

struct Logger;

impl log::Log for Logger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= LOG_LEVEL.to_owned()
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        // Get the log prefix based on the level
        let level = record.metadata().level();
        let (level_text, color) = match level {
            Level::Error => ("ERROR", "[color=red]"),
            Level::Warn => ("WARN", "[color=orange]"),
            Level::Info => ("INFO", "[color=white]"),
            Level::Debug => ("DEBUG", "[color=cyan]"),
            Level::Trace => ("TRACE", "[color=magenta]"),
        };

        let time = INIT_TIME.elapsed().as_millis();
        let args = record.args();
        let file = record.file().unwrap_or_default();
        let line = record.line().unwrap_or_default();

        godot_print_rich!("{color}{time} [{level_text}] [Core] {file}:{line}: {args}[/color]");
    }

    fn flush(&self) {}
}

fn level_from_env() -> Level {
    let level_str = std::env::var("LOG_LEVEL")
        .unwrap_or("info".to_string())
        .to_lowercase();
    let level = str_to_level(level_str.as_str());

    level
}

fn str_to_level(value: &str) -> Level {
    match value {
        "error" => Level::Error,
        "warn" => Level::Warn,
        "info" => Level::Info,
        "debug" => Level::Debug,
        "trace" => Level::Trace,
        _ => Level::Info,
    }
}

/// Initialize the core logger
pub fn init() {
    if let Err(e) = log::set_logger(&LOGGER) {
        godot_error!("Failed to initialize Rust logger: {e:?}");
    }
    log::set_max_level(LOG_LEVEL.to_level_filter());
}

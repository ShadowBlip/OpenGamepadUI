use nix::unistd::mkfifo;
use std::sync::mpsc::{channel, Receiver, Sender, TryRecvError};
use tokio::{io::AsyncReadExt, net::unix::pipe::OpenOptions, select};

use godot::{obj::WithBaseField, prelude::*};

use crate::RUNTIME;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    LineWritten { line: String },
}

/// Commands that can be sent to a pipe
#[derive(Debug)]
enum ControlCommand {
    Close,
}

#[derive(GodotClass)]
#[class(base=Node)]
pub struct FifoReader {
    base: Base<Node>,
    /// Receiver to listen for signals emitted from the async runtime
    rx: Receiver<Signal>,
    /// Transmitter to send signals from the async runtime
    tx: Sender<Signal>,
    /// Transmitter to send commands to the async task
    cmd_tx: Option<tokio::sync::mpsc::Sender<ControlCommand>>,

    /// Whether or not the pipe is currently open
    #[var(get = get_is_open)]
    is_open: bool,
}

#[godot_api]
impl FifoReader {
    /// Emitted when the pipe is opened.
    #[signal]
    fn opened();

    /// Emitted when the pipe is closed.
    #[signal]
    fn closed();

    /// Emitted when a line is written to the pipe.
    #[signal]
    fn line_written(line: GString);

    /// Open the given named pipe
    #[func]
    fn open(&mut self, path: GString) -> i32 {
        if self.is_open {
            log::error!("Named pipe is already open");
            return -1;
        }
        let path = path.to_string();

        // Create the named pipe if it does not exist
        let _ = mkfifo(path.as_str(), nix::sys::stat::Mode::S_IRWXU);

        // Create a channel so input commands can be sent to the running pipe task
        let (cmd_tx, mut cmd_rx) = tokio::sync::mpsc::channel(1);
        self.cmd_tx = Some(cmd_tx);

        // Spawn the async task to handle reading from the pipe
        let signals_tx = self.tx.clone();
        RUNTIME.spawn(async move {
            let mut pipe = match OpenOptions::new().open_receiver(path.as_str()) {
                Ok(rx) => rx,
                Err(e) => {
                    log::error!("Failed to open named pipe {path}: {e}");
                    return;
                }
            };

            // Select between read and command operations in a loop
            loop {
                let mut buffer = [0; 4096];
                select! {
                    // Handle output
                    read_result = pipe.read(&mut buffer) => {
                        let bytes_read = match read_result {
                            Ok(n) => n,
                            Err(_e) => break,
                        };
                        if bytes_read != 0 {
                            Self::process_read(&buffer, bytes_read, &signals_tx);
                            continue;
                        }

                        // Re-open the receiver and wait for other writers if
                        // no other bytes are read
                        pipe = match OpenOptions::new().open_receiver(path.as_str()) {
                            Ok(pipe) => pipe,
                            Err(e) => {
                                log::error!("Failed to re-open named pipe {path}: {e}");
                                break;
                            }
                        };
                    }
                    // Handle process commands
                    Some(cmd) = cmd_rx.recv() => {
                        match cmd {
                            ControlCommand::Close => break,
                        }
                    }
                }
            }
            drop(pipe);

            // Remove the pipe file
            let _ = tokio::fs::remove_file(path).await;
        });

        self.is_open = true;
        self.base_mut().emit_signal("opened", &[]);

        0
    }

    /// Returns whether or not the named pipe is currently opened
    #[func]
    fn get_is_open(&self) -> bool {
        self.is_open
    }

    /// Close the pipe
    #[func]
    fn close(&mut self) -> i32 {
        self.is_open = false;
        let Some(cmd_tx) = self.cmd_tx.take() else {
            log::error!("Named pipe is not open to close");
            return -1;
        };
        let command = ControlCommand::Close;
        if let Err(e) = cmd_tx.blocking_send(command) {
            log::error!("Error sending close command to pipe: {e}");
        }
        self.base_mut().emit_signal("closed", &[]);

        0
    }

    /// Process reading output from the pipe
    fn process_read(buffer: &[u8], bytes_read: usize, signals_tx: &Sender<Signal>) {
        let data = &buffer[..bytes_read];
        let text = String::from_utf8_lossy(data).to_string();
        let text = text.replace('\r', "");
        let lines = text.split('\n');
        for line in lines {
            let line = line.to_string();
            let signal = Signal::LineWritten { line };
            if let Err(e) = signals_tx.send(signal) {
                log::error!("Error sending line: {e:?}");
            }
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::LineWritten { line } => {
                self.base_mut()
                    .emit_signal("line_written", &[line.to_godot().to_variant()]);
            }
        }
    }
}

#[godot_api]
impl INode for FifoReader {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        // Create a channel to communicate with the async runtime
        let (tx, rx) = channel();

        Self {
            base,
            rx,
            tx,
            cmd_tx: None,
            is_open: false,
        }
    }

    /// Executed every engine frame
    fn process(&mut self, _delta: f64) {
        // Drain all messages from the channel to process them
        loop {
            let signal = match self.rx.try_recv() {
                Ok(value) => value,
                Err(e) => match e {
                    TryRecvError::Empty => break,
                    TryRecvError::Disconnected => {
                        log::debug!("Backend thread is not running!");
                        return;
                    }
                },
            };
            self.process_signal(signal);
        }

        // Check to see if the pipe has closed
        if let Some(cmd_tx) = self.cmd_tx.as_ref() {
            if cmd_tx.is_closed() {
                log::debug!("Pipe reader task has stopped");
                self.is_open = false;
                self.cmd_tx = None;
                self.base_mut().emit_signal("closed", &[]);
            }
        }
    }
}

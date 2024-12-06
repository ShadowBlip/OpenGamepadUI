use nix::pty::{openpty, Winsize};
use std::{
    ffi::OsString,
    sync::mpsc::{channel, Receiver, Sender, TryRecvError},
};
use tokio::{
    fs::File,
    io::{AsyncReadExt, AsyncWriteExt, BufReader, BufWriter},
    process::{Child, Command},
    select,
};

use godot::{obj::WithBaseField, prelude::*};

use crate::RUNTIME;

/// Signals that can be emitted
#[derive(Debug)]
enum Signal {
    Started { pid: u32 },
    Finished { exit_code: i32 },
    LineWritten { line: String },
}

/// Commands that can be sent to a running PTY session
#[derive(Debug)]
enum PtyCommand {
    Write { data: Vec<u8> },
    WriteLine { line: String },
}

/// Commands that can be sent to a running child process
#[derive(Debug)]
enum ProcessCommand {
    Kill,
}

#[derive(GodotClass)]
#[class(base=Node)]
pub struct Pty {
    base: Base<Node>,
    /// Receiver to listen for signals emitted from the async runtime
    rx: Receiver<Signal>,
    /// Transmitter to send signals from the async runtime
    tx: Sender<Signal>,
    /// Transmitter to send PTY writes to the PTY async task
    pty_tx: Option<tokio::sync::mpsc::Sender<PtyCommand>>,
    /// Transmitter to send commands to the Process async task
    cmd_tx: Option<tokio::sync::mpsc::Sender<ProcessCommand>>,

    /// Whether or not a process is currently running in the PTY
    #[var(get = get_running)]
    running: bool,
    /// Number of rows the pseudo terminal should have
    #[export]
    rows: i32,
    /// Number of columns the psuedo terminal should have
    #[export]
    columns: i32,
    /// Width of the pseudo terminal in pixels
    #[export]
    width_px: i32,
    /// Height of the pseudo terminal in pixels
    #[export]
    height_px: i32,
}

#[godot_api]
impl Pty {
    /// Emitted when a process is started in the PTY. Returns the PID of the
    /// started process.
    #[signal]
    fn started(pid: i32);

    /// Emitted when a line is written to the PTY stdout
    #[signal]
    fn line_written(line: GString);

    /// Emitted when the underlying command has exited. Returns the exit code
    /// of the child process.
    #[signal]
    fn finished(exit_code: i32);

    /// Returns whether or not the PTY is currently executing a process
    #[func]
    fn get_running(&self) -> bool {
        self.running
    }

    /// Write the given bytes to the running PTY. Returns an error code if the
    /// PTY is not currently executing a process.
    #[func]
    fn write(&self, data: PackedByteArray) -> i32 {
        let Some(pty_tx) = self.pty_tx.as_ref() else {
            log::error!("PTY is not open to write line");
            return -1;
        };
        let slice = data.as_slice();
        let data = slice.to_vec();
        let command = PtyCommand::Write { data };
        if let Err(e) = pty_tx.blocking_send(command) {
            log::error!("Error sending write line to PTY: {e:?}");
            return -1;
        }

        0
    }

    /// Write the given line to the running PTY. Returns an error code if the
    /// PTY is not currently executing a process.
    #[func]
    fn write_line(&self, line: GString) -> i32 {
        let Some(pty_tx) = self.pty_tx.as_ref() else {
            log::error!("PTY is not open to write line");
            return -1;
        };
        let command = PtyCommand::WriteLine { line: line.into() };
        if let Err(e) = pty_tx.blocking_send(command) {
            log::error!("Error sending write line to PTY: {e:?}");
            return -1;
        }

        0
    }

    /// Kill the currently running child process running in the PTY. Returns an
    /// error code if the PTY is not currently executing a process.
    #[func]
    fn kill(&self) -> i32 {
        let Some(cmd_tx) = self.cmd_tx.as_ref() else {
            log::error!("PTY is not open to kill process");
            return -1;
        };
        let command = ProcessCommand::Kill;
        if let Err(e) = cmd_tx.blocking_send(command) {
            log::error!("Error sending kill command to PTY: {e:?}");
            return -1;
        }
        0
    }

    /// Execute the given command inside the PTY. This command is executed
    /// asyncronously and will emit signals whenever new output is available.
    #[func]
    fn exec(&mut self, command: GString, args: PackedStringArray) -> i32 {
        if self.running {
            log::error!("PTY is already running a process");
            return -1;
        }

        // Open a new PTY with the given dimensions
        let window_size = Winsize {
            ws_row: self.rows as u16,
            ws_col: self.columns as u16,
            ws_xpixel: self.width_px as u16,
            ws_ypixel: self.height_px as u16,
        };
        let pty = match openpty(Some(&window_size), None) {
            Ok(pty) => pty,
            Err(e) => {
                log::error!("Failed to open pty: {e}");
                return -1;
            }
        };

        log::debug!("Executing command async in pty");
        let command: String = command.into();
        let command = OsString::from(command);
        let args: Vec<String> = args.as_slice().iter().map(String::from).collect();

        // Assign the different sides of the PTY
        let master = pty.master;
        let slave = pty.slave;
        let stdin = slave.try_clone().unwrap();
        let stdout = slave.try_clone().unwrap();
        let stderr = slave;

        // Create a channel so process commands can be sent to the running process task
        let (cmd_tx, cmd_rx) = tokio::sync::mpsc::channel(64);
        self.cmd_tx = Some(cmd_tx);

        // Spawn a task to run the command
        let signals_tx = self.tx.clone();
        RUNTIME.spawn(async move {
            let mut binding = Command::new(command.clone());
            let cmd = binding
                .args(args)
                .stdin(stdin)
                .stdout(stdout)
                .stderr(stderr);
            let child = match cmd.spawn() {
                Ok(child) => child,
                Err(e) => {
                    log::error!("Failed to spawn child process with command: {command:?} {e:?}");
                    let signal = Signal::Finished { exit_code: -1 };
                    if let Err(e) = signals_tx.send(signal) {
                        log::error!("Error sending exit code: {e:?}");
                    }
                    return;
                }
            };

            // Get the PID of the process and emit a started signal
            let pid = child.id();
            if let Some(pid) = pid {
                let signal = Signal::Started { pid };
                if let Err(e) = signals_tx.send(signal) {
                    log::error!("Error sending started signal: {e:?}");
                }
            }

            // Wait for the process to finish
            let exit_code = Pty::process_child(child, cmd_rx).await;

            // Send the exit code with the finished signal
            let signal = Signal::Finished { exit_code };
            if let Err(e) = signals_tx.send(signal) {
                log::error!("Error sending exit code: {e:?}");
            }
        });

        // Create a channel so input commands can be sent to the running PTY task
        let (pty_tx, mut pty_rx) = tokio::sync::mpsc::channel(8192);
        self.pty_tx = Some(pty_tx);

        // Spawn a task to read/write from/to the PTY
        let signals_tx = self.tx.clone();
        RUNTIME.spawn(async move {
            log::debug!("Task spawned to read/write PTY");

            // Create readers/writers
            let output = std::fs::File::from(master.try_clone().unwrap());
            let output: File = output.into();
            let input = std::fs::File::from(master);
            let input: File = input.into();

            let mut reader = BufReader::new(output);
            let mut writer = BufWriter::new(input);

            // Select between read and write operations in a loop
            loop {
                let mut buffer = [0; 4096];
                select! {
                    // Handle stdout output
                    read_result = reader.read(&mut buffer[..]) => {
                        let bytes_read = match read_result {
                            Ok(n) => n,
                            Err(_e) => break,
                        };
                        Pty::process_read(&buffer, bytes_read, &signals_tx);
                    }
                    // Handle stdin commands over channel
                    Some(cmd) = pty_rx.recv() => {
                        Pty::process_write(&mut writer, cmd).await;
                    }
                }
            }
            log::debug!("Finished");
        });
        self.running = true;

        0
    }

    /// Process waiting for the child process and any process commands (like kill).
    /// Returns the exit code of the child when it finishes.
    async fn process_child(
        mut child: Child,
        mut cmd_rx: tokio::sync::mpsc::Receiver<ProcessCommand>,
    ) -> i32 {
        loop {
            select! {
                // Handle waiting for child exit
                child_result = child.wait() => {
                    let status = match child_result {
                        Ok(status) => status,
                        Err(e) => {
                            log::error!("Error executing child: {e:?}");
                            break -1;
                        }
                    };
                    let exit_code = status.code().unwrap_or(0);
                    break exit_code;
                }
                // Handle process commands
                Some(cmd) = cmd_rx.recv() => {
                    match cmd {
                        ProcessCommand::Kill => {
                            child.start_kill().unwrap_or_default();
                        }
                    }
                }
            }
        }
    }

    /// Process reading output from the PTY
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

    /// Process writing input to the PTY
    async fn process_write(writer: &mut BufWriter<File>, cmd: PtyCommand) {
        match cmd {
            PtyCommand::Write { data } => {
                writer.write_all(data.as_slice()).await.unwrap();
            }
            PtyCommand::WriteLine { line } => {
                let line = format!("{line}\r");
                writer.write_all(line.as_bytes()).await.unwrap();
            }
        };
        writer.flush().await.unwrap();
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Started { pid } => {
                self.base_mut().emit_signal("started", &[pid.to_variant()]);
            }
            Signal::Finished { exit_code } => {
                self.running = false;
                self.pty_tx = None;
                self.cmd_tx = None;
                self.base_mut()
                    .emit_signal("finished", &[exit_code.to_variant()]);
            }
            Signal::LineWritten { line } => {
                self.base_mut()
                    .emit_signal("line_written", &[line.to_godot().to_variant()]);
            }
        }
    }
}

#[godot_api]
impl INode for Pty {
    /// Called upon object initialization in the engine
    fn init(base: Base<Self::Base>) -> Self {
        // Create a channel to communicate with the async runtime
        let (tx, rx) = channel();

        Self {
            base,
            rx,
            tx,
            pty_tx: None,
            cmd_tx: None,
            running: false,
            rows: 8000,
            columns: 8000,
            width_px: 8000,
            height_px: 8000,
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
                        log::error!("Backend thread is not running!");
                        return;
                    }
                },
            };
            self.process_signal(signal);
        }
    }
}

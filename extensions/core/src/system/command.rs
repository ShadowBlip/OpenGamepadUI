use std::{
    sync::mpsc::{channel, Receiver, Sender},
    time::{Duration, Instant},
};

use godot::{obj::WithBaseField, prelude::*};

use crate::{resource::resource_registry::ResourceRegistry, RUNTIME};

/// Signals that can be emitted by this class
pub enum Signal {
    Finished {
        stdout: String,
        stderr: String,
        code: i32,
    },
}

/// Class for executing OS commands asyncronously or syncronously.
///
/// The [method execute] method will start executing the given command asyncronously and will fire the [signal finished] signal when the command has completed. The [member stdout], [member stderr], and [member code] will be populated with the commands output and exit code. The [member timeout] property can also be set to abort the running command after a certain amount of time.
///
/// The [method execute_blocking] will execute the given command syncronously, blocking the main thread until the command has completed.
///
/// When using the asyncronous method, the [ResourceProcessor] node [b]must[/b] be added to the scene tree or the [signal finished] signal will never fire.
#[derive(GodotClass)]
#[class(init, base=RefCounted)]
pub struct Command {
    base: Base<RefCounted>,
    /// Receiver to listen for signals emitted from the async runtime
    rx: Option<Receiver<Signal>>,
    /// Transmitter for sending cancellation messages to the running command
    cancel_tx: Option<tokio::sync::mpsc::Sender<()>>,
    /// Time when the command started executing
    start_time: Option<Instant>,

    /// Command to execute
    #[var]
    #[init(val = Default::default())]
    command: GString,
    /// Command arguments to execute
    #[var]
    #[init(val = Default::default())]
    args: Array<GString>,
    /// Standard output of the command after the command has completed.
    #[var]
    #[init(val = Default::default())]
    stdout: GString,
    /// Standard error output of the command after the command has completed.
    #[var]
    #[init(val = Default::default())]
    stderr: GString,
    /// The exit code of the command after executing
    #[var]
    #[init(val = Default::default())]
    code: i32,
    /// Optional timeout in seconds for the command to run when executing asyncronously. Zero indicates no timeout.
    #[var]
    #[init(val = Default::default())]
    timeout: f64,
}

#[godot_api]
impl Command {
    /// Exit code for cancelled commands
    #[constant]
    const EXIT_CODE_CANCEL: i32 = 130;

    /// Emitted when the command has finished executing
    #[signal]
    fn finished(exit_code: i32);

    /// Creates a new [Command] with the given command and arguments
    #[func]
    fn create(command: GString, args: Array<GString>) -> Gd<Self> {
        Gd::from_init_fn(|base| Self {
            base,
            rx: None,
            cancel_tx: None,
            start_time: None,
            command,
            args,
            stdout: Default::default(),
            stderr: Default::default(),
            code: Default::default(),
            timeout: Default::default(),
        })
    }

    /// Cancels the executing command, sending a kill signal to the running process.
    #[func]
    pub fn cancel(&mut self) {
        let Some(cancel) = self.cancel_tx.take() else {
            return;
        };
        if let Err(e) = cancel.blocking_send(()) {
            log::warn!("Failed to send cancellation signal: {e:?}");
        }
    }

    /// Process signals and emit them as Godot signals.
    #[func]
    pub fn process(&mut self, _delta: f64) {
        // If a timeout was specified, check to see if the command should be
        // cancelled.
        if self.timeout > 0.0 {
            if let Some(start_time) = self.start_time {
                let elapsed = start_time.elapsed();
                let timeout = Duration::from_secs_f64(self.timeout);
                if elapsed > timeout {
                    log::debug!(
                        "Timed out waiting for command: {} {:?}",
                        self.command,
                        self.args
                    );
                    self.cancel();
                }
            }
        }

        // Get the signal receiver
        let Some(rx) = self.rx.as_ref() else {
            return;
        };

        // Drain all messages from the channel to process them
        let mut signals = Vec::with_capacity(1);
        loop {
            let Ok(signal) = rx.try_recv() else {
                break;
            };
            signals.push(signal);
        }

        for signal in signals {
            self.process_signal(signal);
        }
    }

    /// Process and dispatch the given signal
    fn process_signal(&mut self, signal: Signal) {
        match signal {
            Signal::Finished {
                stdout,
                stderr,
                code,
            } => {
                self.stdout = stdout.to_godot();
                self.stderr = stderr.to_godot();
                self.code = code;
                self.rx = None;
                self.cancel_tx = None;

                // Schedule unregistering this object from the [ResourceProcessor]
                if let Some(registry) = ResourceRegistry::get_registry().as_mut() {
                    let this: Gd<RefCounted> = self.to_gd().upcast();
                    registry.call_deferred("unregister", &[this.to_variant()]);
                }

                self.base_mut()
                    .emit_signal("finished", &[code.to_variant()]);
            }
        }
    }

    /// Execute the command asyncronously. Will fire the [signal finished] signal when the command has completed. Will return an error code if command is already executing.
    #[func]
    pub fn execute(&mut self) -> i32 {
        if self.rx.is_some() {
            log::error!("Command execution already in progress");
            return -1;
        }

        // Convert the args
        let cmd = self.command.to_string();
        let args: Vec<String> = self.args.iter_shared().map(|v| v.to_string()).collect();

        // Create a communication channel
        let (tx, rx) = channel();
        self.rx = Some(rx);

        // Create a second channel for sending cancel signals to the executing program
        let (cancel_tx, cancel_rx) = tokio::sync::mpsc::channel(1);
        self.cancel_tx = Some(cancel_tx);

        // Spawn a task to run the command
        RUNTIME.spawn(async move {
            Command::run(cmd, args, tx, cancel_rx).await;
        });

        // Set the start time of the command
        self.start_time = Some(Instant::now());

        // Add to [ResourceProcessor]
        if let Some(registry) = ResourceRegistry::get_registry().as_mut() {
            let this: Gd<RefCounted> = self.to_gd().upcast();
            registry.call_deferred("register", &[this.to_variant()]);
        } else {
            log::warn!("Unable to load ResourceRegistry. Signals will not fire unless this class's 'process' method is called every frame.");
        }

        0
    }

    /// Execute the command syncronously, blocking the current thread execution until the command has completed.
    #[func]
    pub fn execute_blocking(&mut self) -> i32 {
        // Convert the args
        let cmd = self.command.to_string();
        let args: Vec<String> = self.args.iter_shared().map(|v| v.to_string()).collect();

        let output = std::process::Command::new(cmd.as_str())
            .args(args.as_slice())
            .output();
        let output = match output {
            Ok(out) => out,
            Err(e) => {
                log::error!("Failed to execute command '{cmd}' {args:?}: {e:?}");
                return -1;
            }
        };

        let code = output.status.code().unwrap_or_default();
        let stdout = String::from_utf8_lossy(output.stdout.as_slice()).to_string();
        let stderr = String::from_utf8_lossy(output.stderr.as_slice()).to_string();

        self.code = code;
        self.stdout = stdout.to_godot();
        self.stderr = stderr.to_godot();

        code
    }

    /// Runs the given command asyncronously in the tokio runtime
    async fn run(
        cmd: String,
        args: Vec<String>,
        tx: Sender<Signal>,
        mut cancel_rx: tokio::sync::mpsc::Receiver<()>,
    ) {
        // Build the command to execute
        let task = tokio::process::Command::new(cmd.as_str())
            .args(args.as_slice())
            .kill_on_drop(true)
            .output();

        // Select between either the command completing or cancelling
        tokio::select! {
            // Branch if command finishes executing
            output = task => {
                // Construct the signal to send based on the output
                let signal = match output {
                    Ok(output) => {
                        let code = output.status.code().unwrap_or_default();
                        let stdout = String::from_utf8_lossy(output.stdout.as_slice()).to_string();
                        let stderr = String::from_utf8_lossy(output.stderr.as_slice()).to_string();
                        Signal::Finished {
                            stdout,
                            stderr,
                            code,
                        }
                    }
                    Err(e) => {
                        log::error!("Failed to execute command '{cmd}' {args:?}: {e:?}");
                        Signal::Finished {
                            stdout: Default::default(),
                            stderr: Default::default(),
                            code: -1,
                        }
                    }
                };

                if let Err(e) = tx.send(signal) {
                    log::error!("Failed to send signal: {e:?}");
                }
            },
            // Branch if cancellation signal was sent
            _ = cancel_rx.recv() => {
                let signal = Signal::Finished {
                    stdout: Default::default(),
                    stderr: Default::default(),
                    code: Command::EXIT_CODE_CANCEL,
                };
                if let Err(e) = tx.send(signal) {
                    log::error!("Failed to send signal: {e:?}");
                }
            }
        }
    }
}

//https://iximiuz.com/en/posts/dealing-with-processes-termination-in-Linux/
//
//https://github.com/nix-rust/nix/pull/1550

use nix::{
    errno::Errno,
    sys::{prctl, wait::wait},
    unistd::{execvp, fork, ForkResult},
};

use std::ffi::{CStr, CString};

use godot::prelude::*;

/// [SubReaper] provides methods for spawning a process in a subreaper.
#[derive(GodotClass)]
#[class(base=RefCounted)]
struct SubReaper {
    base: Base<RefCounted>,
}

#[godot_api]
impl SubReaper {
    /// Spawn a new subreaper process and execute the given command and arguments
    /// under that subreaper. This will force all descendent processes to reparent
    /// themselves to the subreaper instead of PID 1.
    #[func]
    pub fn create_process(command: GString, args: PackedStringArray) -> i32 {
        match unsafe { fork() } {
            // Parent process of the fork. Should return the subreaper process id
            Ok(ForkResult::Parent { child }) => child.into(),

            // Child subreaper process of the fork. The subreaper process will execute
            // the provided command and wait for all its child processes to exit.
            Ok(ForkResult::Child) => {
                Self::subreaper_create_process(command, args);
                0
            }

            // If forking fails, return an invalid PID
            Err(e) => {
                log::error!("Error forking command: {command} | {e}");
                -1
            }
        }
    }

    /// Sets the current process to be a child subreaper and executes the given
    /// command. The subreaper process will wait until all children have exited
    /// before stopping itself.
    fn subreaper_create_process(command: GString, args: PackedStringArray) {
        // Set the current process to be a subreaper. A subreaper MUST wait
        // for all child processes to exit to clean up.
        match prctl::set_child_subreaper(true) {
            Ok(_) => (),
            Err(e) => {
                panic!("Error setting child as subreaper for command: {command} | {e}");
            }
        };

        // Spawn the desired process
        match unsafe { fork() } {
            // Parent process of the fork. Should wait for all child processes
            // to exit.
            Ok(ForkResult::Parent { child: _ }) => {
                // Wait for all child processes to exit
                loop {
                    match wait() {
                        Ok(_) => (),
                        Err(e) => {
                            if e == Errno::ECHILD {
                                break;
                            }
                            println!("Got unexpected error: {e}")
                        }
                    };
                }

                // No "quick_exit" exists, so instead use execvp to run
                // a simple program to exit cleanly.
                println!("No more children for subreaper. Exiting.");
                let cmd = CString::new("true").unwrap();
                match execvp::<&CStr>(cmd.as_c_str(), &[cmd.as_c_str()]) {
                    Ok(_) => (),
                    Err(e) => {
                        panic!("Error exiting subreaper: {e:?}");
                    }
                }
            }

            // Child process of the fork. Should execute the command.
            Ok(ForkResult::Child) => {
                // Convert the command to a CString
                let command = CString::new(command.to_string().as_str()).unwrap();

                // Build the arguments list. The first argument in this list
                // MUST be the command that is being executed.
                let mut c_args: Vec<CString> = vec![command.clone()];
                for arg in args.to_vec() {
                    let c_arg = CString::new(arg.to_string().as_str()).unwrap();
                    c_args.push(c_arg);
                }

                // Execute the command
                match execvp(command.as_c_str(), c_args.as_slice()) {
                    Ok(_) => (),
                    Err(e) => {
                        panic!("Error executing command: {command:?} | {e}");
                    }
                }
            }

            // Panic if forking fails.
            Err(e) => {
                panic!("Error forking subprocess for command: {command} | {e}");
            }
        }
    }
}

#[godot_api]
impl IRefCounted for SubReaper {
    fn init(base: Base<Self::Base>) -> Self {
        Self { base }
    }
}

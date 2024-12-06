use std::{env, ffi::CString, process::exit};

use nix::{
    errno::Errno,
    sys::{
        prctl,
        wait::{wait, WaitStatus},
    },
    unistd::{execvp, fork, ForkResult},
};

fn main() {
    // Parse the arguments that should be passed to the child process
    let args = env::args();
    let mut child_args = vec![];
    let mut end_of_args = false;
    for arg in args {
        if !end_of_args && arg.as_str() == "--" {
            end_of_args = true;
            continue;
        }
        if !end_of_args {
            continue;
        }
        child_args.push(arg);
    }

    // If "--" was not included as an argument, return an error.
    if !end_of_args {
        panic!("reaper: no '--' argument was found");
    }
    if child_args.is_empty() {
        panic!("reaper: no sub-command!");
    }

    // Set the current process to be a subreaper. A subreaper MUST wait
    // for all child processes to exit to clean up.
    if let Err(e) = prctl::set_child_subreaper(true) {
        panic!("reaper: failed to set child subreaper: {e:?}");
    }

    // Fork to spawn the requested process and wait for the subprocesses to exit
    match unsafe { fork() } {
        // Parent process of the fork should wait for all child processes to exit
        Ok(ForkResult::Parent { child }) => {
            println!("reaper: got child PID: {child}");

            // Keep track of child exit codes
            let mut exit_codes = vec![];

            // Wait for all child processes to exit
            loop {
                match wait() {
                    Ok(status) => {
                        if let WaitStatus::Exited(_, code) = status {
                            exit_codes.push(code);
                        }
                    }
                    Err(e) => {
                        if e == Errno::ECHILD {
                            break;
                        }
                        println!("reaper: got unexpected error: {e}")
                    }
                };
            }

            println!("reaper: no more children exist; exiting");

            // Return the exit code of the last exited child process
            let exit_code = exit_codes.last().unwrap_or(&0);
            exit(*exit_code);
        }

        // Child process of the fork should execute the requested command
        Ok(ForkResult::Child) => {
            println!("reaper: executing command: {child_args:?}");

            // Convert the command to a CString
            let cmd = CString::new(child_args.first().unwrap().as_str()).unwrap();

            // Build the arguments list
            let mut c_args = vec![];
            for arg in child_args {
                let c_arg = CString::new(arg.as_str()).unwrap();
                c_args.push(c_arg);
            }

            // Execute the command
            #[allow(irrefutable_let_patterns)]
            if let Err(e) = execvp(cmd.as_c_str(), c_args.as_slice()) {
                panic!("reaper: failed executing command: {e:?}");
            }
        }

        // Panic if forking fails
        Err(e) => {
            panic!("reaper: failed to create fork: {e:?}");
        }
    }
}

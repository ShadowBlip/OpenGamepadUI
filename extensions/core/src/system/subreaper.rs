//https://iximiuz.com/en/posts/dealing-with-processes-termination-in-Linux/
//
//https://github.com/nix-rust/nix/pull/1550

use nix::{
    errno::Errno,
    sys::{prctl, wait::wait},
    unistd::{execvp, fork, ForkResult},
};

use std::{ffi::CString, process::exit};

use godot::{classes::json_rpc::ErrorCode, prelude::*};

#[derive(GodotClass)]
#[class(base=RefCounted)]
struct SubReaper {
    base: Base<RefCounted>,
}

#[godot_api]
impl SubReaper {
    #[func]
    pub fn create_process(command: GString, args: PackedStringArray) -> i32 {
        match unsafe { fork() } {
            Ok(ForkResult::Parent { child }) => {
                // Parent process of the fork. Should return the subreaper process id
                child.into()
            }
            Ok(ForkResult::Child) => {
                // Child reaper process
                match prctl::set_child_subreaper(true) {
                    Ok(_) => (),
                    Err(e) => {
                        panic!("Error setting child as subreaper for command: {command} | {e}");
                    }
                };

                // Spawn the desired process
                match unsafe { fork() } {
                    Ok(ForkResult::Parent { child: _ }) => {
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
                        exit(0);
                    }
                    Ok(ForkResult::Child) => {
                        let command = CString::new(command.to_string().as_str()).unwrap();

                        let mut c_args: Vec<CString> = vec![];
                        for arg in args.to_vec() {
                            let c_arg = CString::new(arg.to_string().as_str()).unwrap();
                            c_args.push(c_arg);
                        }
                        match execvp(command.as_c_str(), c_args.as_slice()) {
                            Ok(_) => (),
                            Err(e) => {
                                panic!("Error executing command: {command:?} | {e}");
                            }
                        }
                    }
                    Err(e) => {
                        panic!("Error forking subprocess for command: {command} | {e}");
                    }
                }

                0
            }
            Err(e) => {
                godot_error!("Error forking command: {command} | {e}");
                -1
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

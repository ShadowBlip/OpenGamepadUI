//https://iximiuz.com/en/posts/dealing-with-processes-termination-in-Linux/
//
//https://github.com/nix-rust/nix/pull/1550

use nix::{
    sys::prctl,
    unistd::{fork, ForkResult},
};

fn foo() {
    match unsafe { fork() } {
        Ok(ForkResult::Parent { child }) => {
            // Parent process of the fork. Should return the subreaper process id
        }
        Ok(ForkResult::Child) => {
            // Child reaper process
            prctl::set_child_subreaper(true);

            // Spawn the desired process
        }
        Err(err) => todo!(),
    }
}

//! Per-user preferences and a durable, exclusive once-per-boot attempt fence.
use super::fan_client::{validate_selection, MAX_PROFILE_BYTES};
use nix::libc;
use serde_json::{json, Value};
use std::{
    fs::{self, File, OpenOptions},
    io::{Read, Write},
    os::{
        fd::{AsRawFd, FromRawFd},
        unix::fs::{DirBuilderExt, MetadataExt, OpenOptionsExt},
    },
    path::PathBuf,
};

pub struct FanSettings {
    directory: PathBuf,
}
impl FanSettings {
    pub fn new(directory: PathBuf) -> Self {
        Self { directory }
    }
    fn directory(&self) -> Result<File, String> {
        fs::DirBuilder::new()
            .recursive(true)
            .mode(0o700)
            .create(&self.directory)
            .map_err(|e| e.to_string())?;
        let directory = OpenOptions::new()
            .read(true)
            .custom_flags(libc::O_DIRECTORY | libc::O_NOFOLLOW | libc::O_CLOEXEC)
            .open(&self.directory)
            .map_err(|e| e.to_string())?;
        let metadata = directory.metadata().map_err(|e| e.to_string())?;
        if metadata.uid() != unsafe { libc::geteuid() } || metadata.mode() & 0o022 != 0 {
            return Err("Fan preference directory is not trusted".into());
        }
        Ok(directory)
    }
    fn read(&self, directory: &File) -> Result<Option<Value>, String> {
        let descriptor = unsafe {
            libc::openat(
                directory.as_raw_fd(),
                c"profile.json".as_ptr(),
                libc::O_RDONLY | libc::O_NOFOLLOW | libc::O_NONBLOCK | libc::O_CLOEXEC,
            )
        };
        if descriptor < 0 {
            let error = std::io::Error::last_os_error();
            if error.kind() == std::io::ErrorKind::NotFound {
                return Ok(None);
            }
            return Err(error.to_string());
        }
        let file = unsafe { File::from_raw_fd(descriptor) };
        let metadata = file.metadata().map_err(|e| e.to_string())?;
        if !metadata.is_file()
            || metadata.uid() != unsafe { libc::geteuid() }
            || metadata.nlink() != 1
            || metadata.mode() & 0o777 != 0o600
            || metadata.len() > MAX_PROFILE_BYTES as u64
        {
            return Err("Saved fan preferences are not a bounded private regular file".into());
        }
        let mut bytes = Vec::new();
        file.take(MAX_PROFILE_BYTES as u64 + 1)
            .read_to_end(&mut bytes)
            .map_err(|e| e.to_string())?;
        if bytes.len() > MAX_PROFILE_BYTES {
            return Err("Saved fan profile is too large".into());
        }
        let data: Value = serde_json::from_slice(&bytes)
            .map_err(|_| "Saved fan preferences are corrupt; the file was preserved")?;
        if data.as_object().is_none_or(|o| o.len() != 2) || data["version"] != 1 {
            return Err("Unsupported saved fan preferences; the file was preserved".into());
        }
        validate_selection(&data["selection"])?;
        Ok(Some(data["selection"].clone()))
    }
    pub fn load(&self) -> Result<Option<Value>, String> {
        if !self.directory.exists() {
            return Ok(None);
        }
        self.read(&self.directory()?)
    }
    pub fn save(&self, selection: &Value) -> Result<(), String> {
        validate_selection(selection)?;
        let directory = self.directory()?;
        // Preserve malformed existing preferences instead of silently replacing them.
        self.read(&directory)?;
        let bytes = json!({"version": 1, "selection": selection}).to_string();
        if bytes.len() > MAX_PROFILE_BYTES {
            return Err("Saved fan preferences exceed 64 KiB".into());
        }
        let name = format!(".profile-{}", std::process::id());
        let path = self.directory.join(&name);
        let mut file = OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o600)
            .custom_flags(libc::O_NOFOLLOW | libc::O_CLOEXEC)
            .open(&path)
            .map_err(|e| e.to_string())?;
        let result = (|| {
            file.write_all(bytes.as_bytes())?;
            file.sync_all()?;
            fs::rename(&path, self.directory.join("profile.json"))?;
            directory.sync_all()
        })()
        .map_err(|e: std::io::Error| e.to_string());
        let _ = fs::remove_file(&path);
        result
    }
    pub fn consume_boot(&self, boot: &str) -> Result<bool, String> {
        if boot.len() != 36
            || !boot.bytes().enumerate().all(|(i, b)| {
                if [8, 13, 18, 23].contains(&i) {
                    b == b'-'
                } else {
                    b.is_ascii_hexdigit() && !b.is_ascii_uppercase()
                }
            })
        {
            return Err("Invalid OS boot identity".into());
        }
        let directory = self.directory()?;
        let name = std::ffi::CString::new(format!("restore-{boot}")).unwrap();
        let first = unsafe { libc::mkdirat(directory.as_raw_fd(), name.as_ptr(), 0o700) } == 0;
        if !first {
            let error = std::io::Error::last_os_error();
            if error.kind() != std::io::ErrorKind::AlreadyExists {
                return Err(error.to_string());
            }
        }
        // The exclusive directory itself is the attempt, even if fsync fails.
        directory.sync_all().map_err(|e| e.to_string())?;
        Ok(first)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;
    use std::sync::atomic::{AtomicU64, Ordering};
    static SEQUENCE: AtomicU64 = AtomicU64::new(0);
    struct Fixture(PathBuf);
    impl Fixture {
        fn new() -> Self {
            Self(std::env::temp_dir().join(format!(
                "ogui-fans-{}-{}",
                std::process::id(),
                SEQUENCE.fetch_add(1, Ordering::Relaxed)
            )))
        }
    }
    impl Drop for Fixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.0);
        }
    }
    const BOOT: &str = "12345678-1234-1234-1234-123456789abc";
    #[test]
    fn preferences_and_boot_attempt_survive_client_restart() {
        let fixture = Fixture::new();
        let settings = FanSettings::new(fixture.0.clone());
        assert_eq!(settings.load().unwrap(), None);
        let selection = json!({"kind":"file", "file":"quiet.yaml"});
        settings.save(&selection).unwrap();
        assert!(settings.consume_boot(BOOT).unwrap());
        let restarted = FanSettings::new(fixture.0.clone());
        assert_eq!(restarted.load().unwrap(), Some(selection));
        assert!(!restarted.consume_boot(BOOT).unwrap());
        assert_eq!(
            fs::metadata(fixture.0.join("profile.json")).unwrap().mode() & 0o777,
            0o600
        );
    }
    #[test]
    fn malformed_oversized_insecure_and_symlink_preferences_are_preserved() {
        let fixture = Fixture::new();
        let settings = FanSettings::new(fixture.0.clone());
        let selection = json!({"kind":"file", "file":"quiet.yaml"});
        settings.save(&selection).unwrap();
        let path = fixture.0.join("profile.json");
        for bytes in [
            "{".to_string(),
            "x".repeat(MAX_PROFILE_BYTES + 1),
            r#"{"version":2,"selection":{}}"#.into(),
        ] {
            fs::write(&path, &bytes).unwrap();
            assert!(settings.load().is_err());
            assert!(settings.save(&selection).is_err());
            assert_eq!(fs::read_to_string(&path).unwrap(), bytes);
        }
        fs::remove_file(&path).unwrap();
        std::os::unix::fs::symlink("missing", &path).unwrap();
        assert!(settings.load().is_err());
        assert!(settings.save(&selection).is_err());
        fs::remove_file(&path).unwrap();
        settings.save(&selection).unwrap();
        fs::set_permissions(&path, fs::Permissions::from_mode(0o644)).unwrap();
        assert!(settings.load().is_err());
        fs::set_permissions(&fixture.0, fs::Permissions::from_mode(0o777)).unwrap();
        assert!(settings.consume_boot(BOOT).is_err());
    }
    #[test]
    fn invalid_identity_cannot_claim_an_attempt() {
        let fixture = Fixture::new();
        let settings = FanSettings::new(fixture.0.clone());
        assert!(settings.consume_boot("../../escape").is_err());
        assert!(!fixture.0.exists());
    }
}

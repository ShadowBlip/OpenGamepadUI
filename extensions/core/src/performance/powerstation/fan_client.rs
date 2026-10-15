//! Owner-pinned API v2 transactions. Saved preferences never contain hardware policy.
use super::POWERSTATION_BUS;
use crate::dbus::powerstation::{
    fan::FanProxy, fan_device::FanDeviceProxy, fan_sensor::FanSensorProxy,
};
use serde_json::{json, Value};
use std::time::Duration;
use zbus::{names::BusName, proxy::CacheProperties, Connection};

pub const TIMEOUT: Duration = Duration::from_secs(3);
pub const MAX_PROFILE_BYTES: usize = 64 * 1024;

pub async fn restore(
    connection: &Connection,
    settings: &super::fan_settings::FanSettings,
) -> Result<(), String> {
    let state = snapshot(connection).await?;
    let startup = &state["startup"];
    if state["available"] != true || startup["eligible"] != true {
        return Err("Saved fan profile was not restored: startup is not eligible. Select a profile explicitly.".into());
    }
    let boot = startup["boot_id"]
        .as_str()
        .ok_or("Missing startup boot identity")?;
    let invocation = startup["invocation_id"]
        .as_str()
        .ok_or("Missing startup invocation identity")?;
    let current_boot =
        std::fs::read_to_string("/proc/sys/kernel/random/boot_id").map_err(|e| e.to_string())?;
    if boot != current_boot.trim() {
        return Err("PowerStation startup belongs to another OS boot".into());
    }
    // The fence precedes preferences and hardware writes. Any later error or
    // uncertain result remains consumed across application restarts.
    if !settings.consume_boot(boot)? {
        return Err("Fan restoration was already attempted this boot".into());
    }
    let Some(selection) = settings.load()? else {
        return Ok(());
    };
    apply(
        connection,
        state["owner"].as_str().unwrap_or_default(),
        &selection,
        Some((boot, invocation)),
    )
    .await
}

async fn current_owner(connection: &Connection) -> Result<String, String> {
    let dbus = zbus::fdo::DBusProxy::new(connection)
        .await
        .map_err(|e| e.to_string())?;
    dbus.get_name_owner(BusName::try_from(POWERSTATION_BUS).unwrap())
        .await
        .map(|owner| owner.to_string())
        .map_err(|e| e.to_string())
}

pub async fn snapshot(connection: &Connection) -> Result<Value, String> {
    let owner = current_owner(connection).await?;
    let result = async {
        let proxy = FanProxy::builder(connection).destination(owner.clone())?
            .cache_properties(CacheProperties::No).build().await?;
        let version = proxy.api_version().await?;
        if version != 2 { return Ok(json!({"available": false, "api_version": version,
            "error": "PowerStation fan API v2 is required", "fans": [], "sensors": []})); }
        let mut fans = Vec::new();
        for path in proxy.enumerate_fans().await? {
            let fan = FanDeviceProxy::builder(connection).destination(owner.clone())?.path(path.clone())?
                .cache_properties(CacheProperties::No).build().await?;
            fans.push(json!({"path": path.as_str(), "id": fan.id().await?, "name": fan.name().await?,
                "mode": fan.mode().await?, "available_modes": fan.available_modes().await?,
                "percent": fan.percent().await?, "percent_valid": fan.percent_valid().await?, "fault": fan.fault().await?}));
        }
        let mut sensors = Vec::new();
        for path in proxy.enumerate_sensors().await? {
            let sensor = FanSensorProxy::builder(connection).destination(owner.clone())?.path(path.clone())?
                .cache_properties(CacheProperties::No).build().await?;
            sensors.push(json!({"path": path.as_str(), "id": sensor.id().await?, "name": sensor.name().await?,
                "temperature_c": sensor.temperature_c().await?, "telemetry_valid": sensor.telemetry_valid().await?}));
        }
        let (boot, invocation, eligible) = proxy.get_startup_status().await?;
        let startup = json!({"boot_id": boot, "invocation_id": invocation, "eligible": eligible});
        Ok::<_, zbus::Error>(json!({"available": true, "api_version": version, "owner": owner,
            "profile_name": proxy.current_profile_name().await?, "profile_path": proxy.current_profile_path().await?,
            "fans": fans, "sensors": sensors, "startup": startup}))
    }.await.map_err(|e| e.to_string())?;
    if current_owner(connection).await? != result["owner"].as_str().unwrap_or_default()
        && result["available"] == true
    {
        return Err("PowerStation changed during the fan snapshot".into());
    }
    Ok(result)
}

pub fn validate_selection(selection: &Value) -> Result<(), String> {
    let object = selection.as_object().ok_or("Invalid saved fan selection")?;
    match selection["kind"].as_str() {
        Some("file") if object.len() == 2 => {
            let file = selection["file"]
                .as_str()
                .ok_or("Missing profile filename")?;
            if file.is_empty() || file.len() > 4096 || file.contains('\0') {
                return Err("Invalid profile filename".into());
            }
        }
        Some("json") if object.len() == 2 => {
            let profile = &selection["profile"];
            let fields = profile.as_object().ok_or("Invalid profile")?;
            if fields.len() != 2
                || profile["name"].as_str().is_none_or(|s| s.trim().is_empty())
                || profile["fans"]
                    .as_array()
                    .is_none_or(|fans| fans.is_empty())
            {
                return Err("A complete named fan profile is required".into());
            }
        }
        _ => return Err("Invalid saved fan selection type".into()),
    }
    if selection.to_string().len() > MAX_PROFILE_BYTES {
        return Err("Fan profile exceeds 64 KiB".into());
    }
    Ok(())
}

pub async fn apply(
    connection: &Connection,
    expected_owner: &str,
    selection: &Value,
    startup: Option<(&str, &str)>,
) -> Result<(), String> {
    validate_selection(selection)?;
    if expected_owner.is_empty() || current_owner(connection).await? != expected_owner {
        return Err("PowerStation changed; refresh before applying a profile".into());
    }
    let result = async {
        let proxy = FanProxy::builder(connection)
            .destination(expected_owner.to_owned())?
            .cache_properties(CacheProperties::No)
            .build()
            .await?;
        if proxy.api_version().await? != 2 {
            return Err(zbus::Error::Failure(
                "PowerStation fan API v2 is required".into(),
            ));
        }
        match (selection["kind"].as_str(), startup) {
            (Some("file"), None) => {
                proxy
                    .load_profile(selection["file"].as_str().unwrap())
                    .await
            }
            (Some("file"), Some((boot, invocation))) => {
                proxy
                    .load_startup_profile(boot, invocation, selection["file"].as_str().unwrap())
                    .await
            }
            (_, None) => {
                proxy
                    .load_profile_json(&selection["profile"].to_string())
                    .await
            }
            (_, Some((boot, invocation))) => {
                proxy
                    .load_startup_profile_json(boot, invocation, &selection["profile"].to_string())
                    .await
            }
        }
    }
    .await;
    result.map_err(|e| e.to_string())?;
    if current_owner(connection).await? != expected_owner {
        return Err("PowerStation changed after the request; application is uncertain and will not be retried".into());
    }
    Ok(())
}

#[cfg(test)]
#[path = "fan_client_test.rs"]
mod tests;

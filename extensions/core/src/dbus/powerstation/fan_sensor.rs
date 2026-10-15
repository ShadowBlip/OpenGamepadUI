use zbus::proxy;

#[proxy(
    interface = "org.shadowblip.Fan.Sensor",
    default_service = "org.shadowblip.PowerStation"
)]
pub trait FanSensor {
    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn name(&self) -> zbus::Result<String>;
    #[zbus(property)]
    fn temperature_c(&self) -> zbus::Result<f64>;
    #[zbus(property)]
    fn telemetry_valid(&self) -> zbus::Result<bool>;
}

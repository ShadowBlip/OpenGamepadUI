use godot::prelude::*;
use zvariant::NoneValue;

pub mod bluez;
pub mod inputplumber;
pub mod powerstation;
pub mod udisks2;
pub mod upower;

/// Possible DBus runtime errors
#[derive(Debug)]
pub enum RunError {
    Zbus(zbus::Error),
    ZbusFdo(zbus::fdo::Error),
}

impl From<zbus::Error> for RunError {
    fn from(value: zbus::Error) -> Self {
        RunError::Zbus(value)
    }
}

impl From<zbus::fdo::Error> for RunError {
    fn from(value: zbus::fdo::Error) -> Self {
        RunError::ZbusFdo(value)
    }
}

pub trait DBusVariant {
    fn as_zvariant(&self) -> Option<zvariant::Value>;
}

impl DBusVariant for Variant {
    /// Convert the Godot variant type into a DBus variant type
    fn as_zvariant(&self) -> Option<zvariant::Value> {
        match self.get_type() {
            VariantType::NIL => {
                let value = zvariant::Optional::<&str>::null_value();
                Some(zvariant::Value::new(value))
            }
            VariantType::BOOL => {
                let value: bool = self.to();
                Some(zvariant::Value::new(value))
            }
            VariantType::INT => {
                let value: i64 = self.to();
                Some(zvariant::Value::new(value))
            }
            VariantType::FLOAT => {
                let value: f64 = self.to();
                Some(zvariant::Value::new(value))
            }
            VariantType::STRING => {
                let value: GString = self.to();
                let value: String = value.into();
                Some(zvariant::Value::new(value))
            }
            VariantType::VECTOR2 => todo!(),
            VariantType::VECTOR2I => todo!(),
            VariantType::RECT2 => todo!(),
            VariantType::RECT2I => todo!(),
            VariantType::VECTOR3 => todo!(),
            VariantType::VECTOR3I => todo!(),
            VariantType::TRANSFORM2D => todo!(),
            VariantType::VECTOR4 => todo!(),
            VariantType::VECTOR4I => todo!(),
            VariantType::PLANE => todo!(),
            VariantType::QUATERNION => todo!(),
            VariantType::AABB => todo!(),
            VariantType::BASIS => todo!(),
            VariantType::TRANSFORM3D => todo!(),
            VariantType::PROJECTION => todo!(),
            VariantType::COLOR => todo!(),
            VariantType::STRING_NAME => todo!(),
            VariantType::NODE_PATH => todo!(),
            VariantType::RID => {
                let value: i64 = self.to();
                Some(zvariant::Value::new(value))
            }
            VariantType::OBJECT => todo!(),
            VariantType::CALLABLE => todo!(),
            VariantType::SIGNAL => todo!(),
            VariantType::DICTIONARY => todo!(),
            VariantType::ARRAY => todo!(),
            VariantType::PACKED_BYTE_ARRAY => todo!(),
            VariantType::PACKED_INT32_ARRAY => todo!(),
            VariantType::PACKED_INT64_ARRAY => todo!(),
            VariantType::PACKED_FLOAT32_ARRAY => todo!(),
            VariantType::PACKED_FLOAT64_ARRAY => todo!(),
            VariantType::PACKED_STRING_ARRAY => todo!(),
            VariantType::PACKED_VECTOR2_ARRAY => todo!(),
            VariantType::PACKED_VECTOR3_ARRAY => todo!(),
            VariantType::PACKED_COLOR_ARRAY => todo!(),
            VariantType::PACKED_VECTOR4_ARRAY => todo!(),
            VariantType::MAX => todo!(),

            // Unsupported conversion
            _ => None,
        }
    }
}

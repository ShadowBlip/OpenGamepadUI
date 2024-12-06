use godot::prelude::*;
use zvariant::NoneValue;

pub mod bluez;
pub mod inputplumber;
pub mod networkmanager;
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

/// Interface for converting DBus types -> Godot types
pub trait GodotVariant {
    fn as_godot_variant(&self) -> Option<Variant>;
}

impl GodotVariant for zvariant::OwnedValue {
    /// Convert the DBus variant type into a Godot variant type
    fn as_godot_variant(&self) -> Option<Variant> {
        let value = zvariant::Value::try_from(self).ok()?;
        value.as_godot_variant()
    }
}

impl<'a> GodotVariant for zvariant::Value<'a> {
    /// Convert the DBus variant type into a Godot variant type
    fn as_godot_variant(&self) -> Option<Variant> {
        match self {
            zvariant::Value::U8(value) => Some(value.to_variant()),
            zvariant::Value::Bool(value) => Some(value.to_variant()),
            zvariant::Value::I16(value) => Some(value.to_variant()),
            zvariant::Value::U16(value) => Some(value.to_variant()),
            zvariant::Value::I32(value) => Some(value.to_variant()),
            zvariant::Value::U32(value) => Some(value.to_variant()),
            zvariant::Value::I64(value) => Some(value.to_variant()),
            zvariant::Value::U64(value) => Some(value.to_variant()),
            zvariant::Value::F64(value) => Some(value.to_variant()),
            zvariant::Value::Str(value) => Some(value.to_string().to_variant()),
            zvariant::Value::Signature(_) => None,
            zvariant::Value::ObjectPath(value) => Some(value.to_string().to_variant()),
            zvariant::Value::Value(_) => None,
            zvariant::Value::Array(value) => {
                let mut arr = array![];
                for item in value.iter() {
                    let Some(variant) = item.as_godot_variant() else {
                        continue;
                    };
                    arr.push(&variant);
                }

                Some(arr.to_variant())
            }
            zvariant::Value::Dict(value) => {
                let mut dict = Dictionary::new();
                for (key, val) in value.iter() {
                    let Some(key) = key.as_godot_variant() else {
                        continue;
                    };
                    let Some(val) = val.as_godot_variant() else {
                        continue;
                    };
                    dict.set(key, val);
                }

                Some(dict.to_variant())
            }
            zvariant::Value::Structure(_) => None,
            zvariant::Value::Fd(_) => None,
        }
    }
}

/// Interface for converting Godot types -> DBus types
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
            VariantType::VECTOR2 => None,
            VariantType::VECTOR2I => None,
            VariantType::RECT2 => None,
            VariantType::RECT2I => None,
            VariantType::VECTOR3 => None,
            VariantType::VECTOR3I => None,
            VariantType::TRANSFORM2D => None,
            VariantType::VECTOR4 => None,
            VariantType::VECTOR4I => None,
            VariantType::PLANE => None,
            VariantType::QUATERNION => None,
            VariantType::AABB => None,
            VariantType::BASIS => None,
            VariantType::TRANSFORM3D => None,
            VariantType::PROJECTION => None,
            VariantType::COLOR => None,
            VariantType::STRING_NAME => None,
            VariantType::NODE_PATH => None,
            VariantType::RID => {
                let value: i64 = self.to();
                Some(zvariant::Value::new(value))
            }
            VariantType::OBJECT => None,
            VariantType::CALLABLE => None,
            VariantType::SIGNAL => None,
            VariantType::DICTIONARY => None,
            VariantType::ARRAY => None,
            VariantType::PACKED_BYTE_ARRAY => None,
            VariantType::PACKED_INT32_ARRAY => None,
            VariantType::PACKED_INT64_ARRAY => None,
            VariantType::PACKED_FLOAT32_ARRAY => None,
            VariantType::PACKED_FLOAT64_ARRAY => None,
            VariantType::PACKED_STRING_ARRAY => None,
            VariantType::PACKED_VECTOR2_ARRAY => None,
            VariantType::PACKED_VECTOR3_ARRAY => None,
            VariantType::PACKED_COLOR_ARRAY => None,
            VariantType::PACKED_VECTOR4_ARRAY => None,
            VariantType::MAX => None,

            // Unsupported conversion
            _ => None,
        }
    }
}

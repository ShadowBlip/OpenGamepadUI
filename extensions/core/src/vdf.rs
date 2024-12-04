use std::borrow::Cow;

use godot::prelude::*;
use keyvalues_parser::{Obj, Value, Vdf as VdfParser};

/// Helper class for creating and parsing VDF data.
///
/// The [Vdf] class enables the [Dictionary] data type to be converted to and from a VDF string. This is useful for (de)serializing data that use Valve's data format.
///
/// [method stringify] is used to convert a [Dictionary] into a VDF string.
///
/// [method parse] is used to convert any existing VDF data into a [Dictionary] that can be used within Godot.
#[derive(GodotClass)]
#[class(init, base=RefCounted)]
pub struct Vdf {
    base: Base<RefCounted>,
    /// Contains the parsed VDF data in [Dictionary] form.
    #[var]
    data: Dictionary,
    error_msg: Option<String>,
}

#[godot_api]
impl Vdf {
    /// Returns an empty string if the last call to [method parse] was successful, or the error message if it failed.
    #[func]
    pub fn get_error_message(&self) -> GString {
        let Some(msg) = self.error_msg.clone() else {
            return GString::new();
        };
        msg.into()
    }

    /// Converts a dictionary to VDF text and returns the result.
    /// The VDF format only allows a single top-level key, so others will be ignored if the given [Dictionary] contains more than one top-level key.
    #[func]
    pub fn stringify(data: Dictionary) -> GString {
        // Get the first entry in the dictionary. Other top-level entries are ignored.
        let Some((key, value)) = data.iter_shared().next() else {
            return GString::new();
        };

        // Convert the key and value variants into VDF keys and values
        let Some(key) = key.as_vdf() else {
            return GString::new();
        };
        let Value::Str(key) = key else {
            return GString::new();
        };
        let Some(value) = value.as_vdf() else {
            return GString::new();
        };

        let vdf = VdfParser::new(key, value);

        vdf.to_string().into()
    }

    /// Attempts to parse the `vdf_text` provided.
    /// Returns an Error. If the parse was successful, it returns OK and the result can be retrieved using [member data]. If unsuccessful, use [method get_error_message] to identify the source of the failure.
    #[func]
    pub fn parse(&mut self, vdf_text: GString) -> i32 {
        let data = vdf_text.to_string();

        // Try to parse the data
        let vdf = match VdfParser::parse(data.as_str()) {
            Ok(parsed) => parsed,
            Err(e) => {
                self.error_msg = Some(e.to_string());
                return -1;
            }
        };

        // Convert the vdf data into a Godot Dictionary
        let mut dict = dict! {};
        let key = vdf.key.to_string();
        let value = match vdf.value {
            Value::Str(value) => value.to_string().to_variant(),
            Value::Obj(obj) => Vdf::obj_to_dict(obj).to_variant(),
        };

        dict.set(key, value);
        self.data = dict;

        0
    }

    /// Attempts to parse the `vdf_string` provided and returns the parsed data.
    /// Returns an empty [Dictionary] if parse failed.
    #[func]
    pub fn parse_string(vdf_string: GString) -> Dictionary {
        let mut dict = dict! {};
        let data = vdf_string.to_string();

        // Try to parse the data
        let vdf = match VdfParser::parse(data.as_str()) {
            Ok(parsed) => parsed,
            Err(_) => {
                return dict;
            }
        };

        // Convert the vdf data into a Godot Dictionary
        let key = vdf.key.to_string();
        let value = match vdf.value {
            Value::Str(value) => value.to_string().to_variant(),
            Value::Obj(obj) => Vdf::obj_to_dict(obj).to_variant(),
        };
        dict.set(key, value);

        dict
    }

    /// Convert the given VDF object into a Godot Dictionary
    fn obj_to_dict(obj: Obj) -> Dictionary {
        let mut dict = dict! {};

        for vdf in obj.into_vdfs() {
            let key = vdf.key.to_string();
            let value = match vdf.value {
                Value::Str(value) => value.to_string().to_variant(),
                Value::Obj(obj) => Vdf::obj_to_dict(obj).to_variant(),
            };

            dict.set(key, value);
        }

        dict
    }

    /// Convert the given Godot Dictionary into a VDF object
    fn dict_to_obj<'a>(dict: &'a Dictionary, obj: &'a mut Obj) {
        for (key, value) in dict.iter_shared() {
            // Convert the key and value variants into VDF keys and values
            let Some(key) = key.as_vdf() else {
                continue;
            };
            let Value::Str(key) = key else {
                continue;
            };
            let Some(value) = value.as_vdf() else {
                continue;
            };
            let value = Vdf::value_copy(&value);

            let value_vec = vec![value];
            obj.insert(Cow::from(key.to_string()), value_vec);
        }
    }

    /// Convert the given array into a VDF-friendly dictionary
    fn array_to_dict(value: &Array<Variant>) -> Dictionary {
        let mut dict = dict! {};
        for (i, value) in value.iter_shared().enumerate() {
            dict.set(i.to_string(), value);
        }

        dict
    }

    /// Creates a copied version of the given VDF value
    fn value_copy<'a>(value: &Value) -> Value<'a> {
        match value {
            Value::Str(v) => Value::Str(Cow::from(v.to_string())),
            Value::Obj(obj) => {
                let mut obj_copy = Obj::new();

                for (key, values) in obj.iter() {
                    let key = Cow::from(key.to_string());
                    let mut copied_values = Vec::with_capacity(values.len());
                    for value in values {
                        let new_value = Vdf::value_copy(value);
                        copied_values.push(new_value);
                    }
                    obj_copy.insert(key, copied_values);
                }

                Value::Obj(obj_copy)
            }
        }
    }
}

/// Trait for converting Godot variant values into Vdf values
pub trait VdfVariant {
    fn as_vdf(&self) -> Option<Value>;
}

impl VdfVariant for Variant {
    fn as_vdf(&self) -> Option<Value> {
        match self.get_type() {
            VariantType::NIL => None,
            VariantType::BOOL => {
                let value: bool = self.to();
                let value = if value { "true" } else { "false" };
                Some(Value::Str(Cow::from(value)))
            }
            VariantType::INT => {
                let value: i64 = self.to();
                Some(Value::Str(Cow::from(value.to_string())))
            }
            VariantType::FLOAT => {
                let value: f64 = self.to();
                Some(Value::Str(Cow::from(value.to_string())))
            }
            VariantType::STRING => {
                let value: GString = self.to();
                let value: String = value.into();
                Some(Value::Str(Cow::from(value)))
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
                Some(Value::Str(Cow::from(value.to_string())))
            }
            VariantType::OBJECT => None,
            VariantType::CALLABLE => None,
            VariantType::SIGNAL => None,
            VariantType::DICTIONARY => {
                let value: Dictionary = self.to();
                let mut obj = Obj::new();
                Vdf::dict_to_obj(&value, &mut obj);
                Some(Value::Obj(obj))
            }
            VariantType::ARRAY => {
                let value: Array<Variant> = self.to();
                let dict = Vdf::array_to_dict(&value);
                let mut obj = Obj::new();
                Vdf::dict_to_obj(&dict, &mut obj);
                Some(Value::Obj(obj))
            }
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

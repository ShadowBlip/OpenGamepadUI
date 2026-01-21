# PackageVerifier

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Verify cryptographic signatures on packages
## Description

Provides method for validating cryptographic signatures on packages to ensure only valid packages are loaded.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [public_key](./#public_key) | "res://assets/crypto/keys/opengamepadui.pub" |
| [Crypto](https://docs.godotengine.org/en/stable/classes/class_crypto.html) | [crypto](./#crypto) | <unknown> |
| [CryptoKey](https://docs.godotengine.org/en/stable/classes/class_cryptokey.html) | [pubkey](./#pubkey) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_valid_signature](./#has_valid_signature)(data: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html), signature: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [file_has_valid_signature](./#file_has_valid_signature)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), signature: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html)) |
| [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html) | [get_hash](./#get_hash)(data: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_hash_string](./#get_hash_string)(data: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2) |
| [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html) | [get_file_hash](./#get_file_hash)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_file_hash_string](./#get_file_hash_string)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2) |


------------------

## Property Descriptions

### `public_key`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) public_key = <span style="color: red;">"res://assets/crypto/keys/opengamepadui.pub"</span>


Path to the public key used to verify signatures
### `crypto`


[Crypto](https://docs.godotengine.org/en/stable/classes/class_crypto.html) crypto


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `pubkey`


[CryptoKey](https://docs.godotengine.org/en/stable/classes/class_cryptokey.html) pubkey


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `has_valid_signature()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_valid_signature**(data: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html), signature: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html))


Returns true if the given data matches the given signature data.
### `file_has_valid_signature()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **file_has_valid_signature**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), signature: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html))


Loads the file at the given path and returns true if its contents match the given signature.
### `get_hash()`


[PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html) **get_hash**(data: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2)


Returns the hash of the given data
### `get_hash_string()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_hash_string**(data: [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2)


Get the hash of the given data as a hex encoded string
### `get_file_hash()`


[PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html) **get_file_hash**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2)


Returns the hash of the file at the given path
### `get_file_hash_string()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_file_hash_string**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), type: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 2)


Get the hash of the file at the given path as a hex encoded string

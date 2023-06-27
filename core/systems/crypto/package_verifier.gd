extends Resource
class_name PackageVerifier

## Verify cryptographic signatures on packages
##
## Provides method for validating cryptographic signatures on packages to ensure
## only valid packages are loaded.

## Path to the public key used to verify signatures
@export_file("*.pub") var public_key := "res://assets/crypto/keys/opengamepadui.pub"

var crypto := Crypto.new()
var pubkey := CryptoKey.new()
var logger := Log.get_logger("PackageVerifier")


func _init() -> void:
	if pubkey.load(public_key, true) != OK:
		logger.error("Unable to load public key!")
		return


## Returns true if the given data matches the given signature data.
func has_valid_signature(data: PackedByteArray, signature: PackedByteArray) -> bool:
	var hash := get_hash(data)
	return crypto.verify(HashingContext.HASH_SHA256, hash, signature, pubkey)


## Loads the file at the given path and returns true if its contents match the
## given signature.
func file_has_valid_signature(path: String, signature: PackedByteArray) -> bool:
	if not FileAccess.file_exists(path):
		logger.warn("File does not exist at path: " + path)
		return false
	var data := FileAccess.get_file_as_bytes(path)
	return has_valid_signature(data, signature)


## Returns the hash of the given data
func get_hash(data: PackedByteArray, type: HashingContext.HashType = HashingContext.HASH_SHA256) -> PackedByteArray:
	var ctx = HashingContext.new()
	ctx.start(type)
	ctx.update(data)

	return ctx.finish()


## Get the hash of the given data as a hex encoded string
func get_hash_string(data: PackedByteArray, type: HashingContext.HashType = HashingContext.HASH_SHA256) -> String:
	return get_hash(data, type).hex_encode()


## Returns the hash of the file at the given path
func get_file_hash(path: String, type: HashingContext.HashType = HashingContext.HASH_SHA256) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		logger.warn("File does not exist at path: " + path)
		return PackedByteArray()
	var data := FileAccess.get_file_as_bytes(path)
	
	return get_hash(data, type)


## Get the hash of the file at the given path as a hex encoded string
func get_file_hash_string(path: String, type: HashingContext.HashType = HashingContext.HASH_SHA256) -> String:
	return get_file_hash(path, type).hex_encode()

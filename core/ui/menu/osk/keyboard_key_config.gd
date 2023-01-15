extends Resource
class_name KeyboardKeyConfig

# Defines the key type
enum TYPE {
	CHAR,
	SPECIAL,
}

@export var type: TYPE
@export var output: String
@export var display: String
@export var display_uppercase: String
@export var icon: Texture2D
@export var stretch_ratio: float = 1

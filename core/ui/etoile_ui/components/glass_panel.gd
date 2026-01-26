@tool
extends MarginContainer

@export_category("Shape")
@export_enum("Circle", "Rectangle") var shape_type := "Rectangle":
	set(v):
		shape_type = v
		if not shader:
			return
		var kind := 0
		if shape_type == "Rectangle":
			kind = 1
		shader.set_shader_parameter("shape_type", kind)
@export_category("Corners")
@export var corner_radius_top_left := 10.0:
	set(v):
		corner_radius_top_left = v
		_set_shader_parameter("corner_radius_top_left", v)
@export var corner_radius_top_right := 10.0:
	set(v):
		corner_radius_top_right = v
		_set_shader_parameter("corner_radius_top_right", v)
@export var corner_radius_bottom_left := 10.0:
	set(v):
		corner_radius_bottom_left = v
		_set_shader_parameter("corner_radius_bottom_left", v)
@export var corner_radius_bottom_right := 10.0:
	set(v):
		corner_radius_bottom_right = v
		_set_shader_parameter("corner_radius_bottom_right", v)
@export var circle_radius := 100.0:
	set(v):
		circle_radius = v
		_set_shader_parameter("circle_radius", v)
@export_category("Outline")
@export var outline_enabled := false:
	set(v):
		outline_enabled = v
		_set_shader_parameter("outline_enabled", v)
@export var outline_width := 2.0:
	set(v):
		outline_width = v
		_set_shader_parameter("outline_width", v)
@export var outline_color := Color(1, 1, 1, 0.8):
	set(v):
		outline_color = v
		_set_shader_parameter("outline_color", v)
@export_category("Shadow")
@export var shadow_enabled := true:
	set(v):
		shadow_enabled = v
		_set_shader_parameter("shadow_enabled", v)
@export var shadow_color := Color(0, 0, 0, 0.5):
	set(v):
		shadow_color = v
		_set_shader_parameter("shadow_color", v)
@export var shadow_offset := Vector2(10.0, 10.0):
	set(v):
		shadow_offset = v
		_set_shader_parameter("shadow_offset", v)
@export_category("Edge")
@export var edge_softness := 1.0:
	set(v):
		edge_softness = v
		_set_shader_parameter("edge_softness", v)
@export_category("Color")
@export var shape_color := Color(0.0, 0.0, 0.0):
	set(v):
		shape_color = v
		_set_shader_parameter("shape_color", v)
@export var color_gradient_x := 0.0:
	set(v):
		color_gradient_x = v
		_set_shader_parameter("color_gradient_x", v)
@export var color_gradient_y := 0.0:
	set(v):
		color_gradient_y = v
		_set_shader_parameter("color_gradient_y", v)
@export var color_multiplier := 0.9:
	set(v):
		color_multiplier = v
		_set_shader_parameter("color_multiplier", v)
@export_category("Blur")
@export var enable_screen_blur := true:
	set(v):
		enable_screen_blur = v
		_set_shader_parameter("enable_screen_blur", v)
@export var blur_amount := 3.0:
	set(v):
		blur_amount = v
		_set_shader_parameter("blur_amount", v)
@export var blur_samples := 4:
	set(v):
		blur_samples = v
		_set_shader_parameter("blur_samples", v)
@export var glass_opacity := 0.2:
	set(v):
		glass_opacity = v
		_set_shader_parameter("glass_opacity", v)

@onready var glass_rect := %GlassRect as ColorRect
@onready var shader := glass_rect.material as ShaderMaterial


func _ready() -> void:
	sort_children.connect(_on_sort_children)


func _on_sort_children() -> void:
	shader.set_shader_parameter("node_size", self.size)
	shader.set_shader_parameter("rect_size", self.size)
	glass_rect.size = self.size


func _set_shader_parameter(param: String, value: Variant) -> void:
	if not shader:
		return
	shader.set_shader_parameter(param, value)

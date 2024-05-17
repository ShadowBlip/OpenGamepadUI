extends Resource
class_name InputIconKeyboardMapping

## Name of the icon mapping
@export var name: String

@export_category("Mouse")
@export var mouse_left: Texture
@export var mouse_middle: Texture
@export var mouse_right: Texture
@export var mouse_wheel: Texture

@export_category("Keyboard")
@export var esc: Texture
@export var tab: Texture
@export var backspace_alt: Texture
@export var enter_alt: Texture
@export var enter_tall: Texture
@export var insert: Texture
@export var del: Texture
@export var print_screen: Texture
@export var home: Texture
@export var end: Texture
@export var arrow_left: Texture
@export var arrow_up: Texture
@export var arrow_right: Texture
@export var arrow_down: Texture
@export var page_up: Texture
@export var page_down: Texture
@export var shift_alt: Texture
@export var ctrl: Texture
@export var command: Texture
@export var meta: Texture
@export var alt: Texture
@export var caps_lock: Texture
@export var num_lock: Texture
@export var f1: Texture
@export var f2: Texture
@export var f3: Texture
@export var f4: Texture
@export var f5: Texture
@export var f6: Texture
@export var f7: Texture
@export var f8: Texture
@export var f9: Texture
@export var f10: Texture
@export var f11: Texture
@export var f12: Texture
@export var asterisk: Texture
@export var minus: Texture
@export var plus_tall: Texture
@export var num_0: Texture
@export var num_1: Texture
@export var num_2: Texture
@export var num_3: Texture
@export var num_4: Texture
@export var num_5: Texture
@export var num_6: Texture
@export var num_7: Texture
@export var num_8: Texture
@export var num_9: Texture
@export var space: Texture
@export var quote: Texture
@export var plus: Texture
@export var semicolon: Texture
@export var mark_left: Texture
@export var mark_right: Texture
@export var question: Texture
@export var a: Texture
@export var b: Texture
@export var c: Texture
@export var d: Texture
@export var e: Texture
@export var f: Texture
@export var g: Texture
@export var h: Texture
@export var i: Texture
@export var j: Texture
@export var k: Texture
@export var l: Texture
@export var m: Texture
@export var n: Texture
@export var o: Texture
@export var p: Texture
@export var q: Texture
@export var r: Texture
@export var s: Texture
@export var t: Texture
@export var u: Texture
@export var v: Texture
@export var w: Texture
@export var x: Texture
@export var y: Texture
@export var z: Texture
@export var bracket_left: Texture
@export var slash: Texture
@export var bracket_right: Texture
@export var tilda: Texture


## Return the texture in the mapping from the given path
func get_texture(path: String) -> Texture:
	match path:
		"key/esc":
			return self.esc
		"key/tab":
			return self.tab
		"key/backspace_alt":
			return self.backspace_alt
		"key/return", "key/enter", "key/enter_alt":
			return self.enter_alt
		"key/enter_tall":
			return self.enter_tall
		"key/insert":
			return self.insert
		"key/del":
			return self.del
		"key/print_screen":
			return self.print_screen
		"key/home":
			return self.home
		"key/end":
			return self.end
		"key/arrow_left":
			return self.arrow_left
		"key/arrow_up":
			return self.arrow_up
		"key/arrow_right":
			return self.arrow_right
		"key/arrow_down":
			return self.arrow_down
		"key/page_up":
			return self.page_up
		"key/page_down":
			return self.page_down
		"key/shift_alt":
			return self.shift_alt
		"key/ctrl":
			return self.ctrl
		"key/command":
			return self.command
		"key/meta":
			return self.meta
		"key/alt":
			return self.alt
		"key/caps_lock":
			return self.caps_lock
		"key/num_lock":
			return self.num_lock
		"key/f1":
			return self.f1
		"key/f2":
			return self.f2
		"key/f3":
			return self.f3
		"key/f4":
			return self.f4
		"key/f5":
			return self.f5
		"key/f6":
			return self.f6
		"key/f7":
			return self.f7
		"key/f8":
			return self.f8
		"key/f9":
			return self.f9
		"key/f10":
			return self.f10
		"key/f11":
			return self.f11
		"key/f12":
			return self.f12
		"key/asterisk":
			return self.asterisk
		"key/minus":
			return self.minus
		"key/plus_tall":
			return self.plus_tall
		"key/0":
			return self.num_0
		"key/1":
			return self.num_1
		"key/2":
			return self.num_2
		"key/3":
			return self.num_3
		"key/4":
			return self.num_4
		"key/5":
			return self.num_5
		"key/6":
			return self.num_6
		"key/7":
			return self.num_7
		"key/8":
			return self.num_8
		"key/9":
			return self.num_9
		"key/space":
			return self.space
		"key/quote":
			return self.quote
		"key/plus":
			return self.plus
		"key/semicolon":
			return self.semicolon
		"key/mark_left":
			return self.mark_left
		"key/mark_right":
			return self.mark_right
		"key/question":
			return self.question
		"key/a":
			return self.a
		"key/b":
			return self.b
		"key/c":
			return self.c
		"key/d":
			return self.d
		"key/e":
			return self.e
		"key/f":
			return self.f
		"key/g":
			return self.g
		"key/h":
			return self.h
		"key/i":
			return self.i
		"key/j":
			return self.j
		"key/k":
			return self.k
		"key/l":
			return self.l
		"key/m":
			return self.m
		"key/n":
			return self.n
		"key/o":
			return self.o
		"key/p":
			return self.p
		"key/q":
			return self.q
		"key/r":
			return self.r
		"key/s":
			return self.s
		"key/t":
			return self.t
		"key/u":
			return self.u
		"key/v":
			return self.v
		"key/w":
			return self.w
		"key/x":
			return self.x
		"key/y":
			return self.y
		"key/z":
			return self.z
		"key/bracket_left":
			return self.bracket_left
		"key/slash":
			return self.slash
		"key/bracket_right":
			return self.bracket_right
		"key/tilda":
			return self.tilda
		"mouse/left":
			return self.mouse_left
		"mouse/right":
			return self.mouse_right
		"mouse/middle":
			return self.mouse_middle
		"mouse/wheel":
			return self.mouse_wheel

	return null

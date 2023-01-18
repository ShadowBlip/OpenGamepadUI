extends Resource
class_name KeyboardLayout

@export var name: String = "Default"
@export var rows: Array[Array] = [
	[
		KeyboardKeyConfig.new("`", "~"),
		KeyboardKeyConfig.new("1", "!"),
		KeyboardKeyConfig.new("2", "@"),
		KeyboardKeyConfig.new("3", "#"),
		KeyboardKeyConfig.new("4", "$"),
		KeyboardKeyConfig.new("5", "%"),
		KeyboardKeyConfig.new("6", "^"),
		KeyboardKeyConfig.new("7", "&"),
		KeyboardKeyConfig.new("8", "*"),
		KeyboardKeyConfig.new("9", "("),
		KeyboardKeyConfig.new("0", ")"),
		KeyboardKeyConfig.new("-", "_"),
		KeyboardKeyConfig.new("=", "+"),
		KeyboardKeyConfig.new("", "", "BACKSPACE", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.BKSP, null, 1.5),
	],
	[
		KeyboardKeyConfig.new("", "", "TAB", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.TAB, null, 1),
		KeyboardKeyConfig.new("q", "Q"),
		KeyboardKeyConfig.new("w", "W"),
		KeyboardKeyConfig.new("e", "E"),
		KeyboardKeyConfig.new("r", "R"),
		KeyboardKeyConfig.new("t", "T"),
		KeyboardKeyConfig.new("y", "Y"),
		KeyboardKeyConfig.new("u", "U"),
		KeyboardKeyConfig.new("i", "I"),
		KeyboardKeyConfig.new("o", "O"),
		KeyboardKeyConfig.new("p", "P"),
		KeyboardKeyConfig.new("[", "{"),
		KeyboardKeyConfig.new("]", "}"),
		KeyboardKeyConfig.new("\\", "|"),
	],
	[
		KeyboardKeyConfig.new("", "", "CAPS", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.CAPS, null, 1.25),
		KeyboardKeyConfig.new("a", "A"),
		KeyboardKeyConfig.new("s", "S"),
		KeyboardKeyConfig.new("d", "D"),
		KeyboardKeyConfig.new("f", "F"),
		KeyboardKeyConfig.new("g", "G"),
		KeyboardKeyConfig.new("h", "H"),
		KeyboardKeyConfig.new("j", "J"),
		KeyboardKeyConfig.new("k", "K"),
		KeyboardKeyConfig.new("l", "L"),
		KeyboardKeyConfig.new(";", ":"),
		KeyboardKeyConfig.new("'", "\""),
		KeyboardKeyConfig.new("", "", "ENTER", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.ENTER, null, 2),
	],
	[
		KeyboardKeyConfig.new("", "", "SHIFT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.SHIFT, null, 1.5),
		KeyboardKeyConfig.new("z", "Z"),
		KeyboardKeyConfig.new("x", "X"),
		KeyboardKeyConfig.new("c", "C"),
		KeyboardKeyConfig.new("v", "V"),
		KeyboardKeyConfig.new("b", "B"),
		KeyboardKeyConfig.new("n", "N"),
		KeyboardKeyConfig.new("m", "M"),
		KeyboardKeyConfig.new(",", "<"),
		KeyboardKeyConfig.new(".", ">"),
		KeyboardKeyConfig.new("/", "?"),
		KeyboardKeyConfig.new("", "", "SHIFT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.SHIFT, null, 1.5),
	],
	[
		KeyboardKeyConfig.new("", "", "CTRL", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.CTRL, null, 1),
		KeyboardKeyConfig.new("", "", "SUPER", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.SUPER, null, 1),
		KeyboardKeyConfig.new("", "", "ALT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.ALT, null, 1),
		KeyboardKeyConfig.new(" ", " ", "", "", KeyboardKeyConfig.TYPE.CHAR, \
			KeyboardKeyConfig.ACTION.NONE, null, 6),
		KeyboardKeyConfig.new("", "", "<", "<", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.LEFT, null, 1),
		KeyboardKeyConfig.new("", "", ">", ">", KeyboardKeyConfig.TYPE.SPECIAL, \
			KeyboardKeyConfig.ACTION.RIGHT, null, 1),
	],
]

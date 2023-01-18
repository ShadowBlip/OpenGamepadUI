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
		KeyboardKeyConfig.new("BKSP", "", "BKSP", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1.5),
	],
	[
		KeyboardKeyConfig.new("TAB", "", "TAB", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1),
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
		KeyboardKeyConfig.new("CAPS", "", "CAPS", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1.25),
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
		KeyboardKeyConfig.new("ENTER", "", "ENTR", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 2),
	],
	[
		KeyboardKeyConfig.new("SHIFT", "", "SHIFT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1.5),
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
		KeyboardKeyConfig.new("SHIFT", "", "SHIFT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1.5),
	],
	[
		KeyboardKeyConfig.new("CTRL", "", "CTRL", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1),
		KeyboardKeyConfig.new("SUPER", "", "SUPR", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1),
		KeyboardKeyConfig.new("ALT", "", "ALT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1),
		KeyboardKeyConfig.new("SPACE", "", "SPACE", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 6),
		KeyboardKeyConfig.new("ALT", "", "ALT", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1),
		KeyboardKeyConfig.new("CTRL", "", "CTRL", "", KeyboardKeyConfig.TYPE.SPECIAL, \
			null, 1),
	],
]

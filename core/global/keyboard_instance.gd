extends Resource
class_name KeyboardInstance

signal keyboard_opened
signal keyboard_closed
signal keyboard_populated
signal context_changed(ctx: KeyboardContext)

var context: KeyboardContext

# Opens the OSK with the given context. The keyboard context determines where
# keyboard inputs should go, and how to handle submits.
func open(ctx: KeyboardContext) -> void:
	set_context(ctx)
	keyboard_opened.emit()


# Closes the OSK
func close() -> void:
	set_context(null)
	keyboard_closed.emit()


# Configure the keyboard to use the given context. The keyboard context determines where
# keyboard inputs should go, and how to handle submits.
func set_context(ctx: KeyboardContext) -> void:
	if not ctx:
		if context:
			context.exited.emit()
		context = null
		return

	# If the target is a Godot TextEdit, update the caret position on context change
	if ctx.target != null and ctx.target is TextEdit:
		var text_edit := ctx.target as TextEdit
		var lines := text_edit.get_line_count()
		text_edit.set_caret_line(lines-1)
		var current_line := text_edit.get_line(lines-1)
		text_edit.set_caret_column(current_line.length())
		#text_edit.clear()
		
	# Update our internal keyboard context
	if context == ctx:
		return
	if context:
		context.exited.emit()
	context = ctx
	context_changed.emit(ctx)
	ctx.entered.emit()


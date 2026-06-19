extends Camera2D

var dragging = false
const LEFT_EDGE = -4800
const RIGHT_EDGE = 4800
const UPPER_EDGE = 2700
const LOWER_EDGE = -2700
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			else:
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom *= (1.0 + 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom *= (1.0 - 0.1)
		
		zoom.x = clamp(zoom.x, 0.2, 4)
		zoom.y = clamp(zoom.y, 0.2, 4)
	elif event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom
	
	

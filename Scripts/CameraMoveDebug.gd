extends Camera2D

var LastMouseCoords = get_global_mouse_position()
var CurrentMouseCoords = LastMouseCoords
var dragState = false

func _process(delta):
	CurrentMouseCoords = get_global_mouse_position()
	if dragState:
		var diff = LastMouseCoords - CurrentMouseCoords
		translate(diff)
	LastMouseCoords = CurrentMouseCoords

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_MIDDLE:
		if not dragState:
		    dragState = true
		else:
			dragState = false
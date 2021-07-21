extends Camera2D

onready var LastMouseCoords = get_viewport().get_mouse_position()
var CurrentMouseCoords = LastMouseCoords
var dragState = false

func _process(_delta):
	CurrentMouseCoords = get_viewport().get_mouse_position()
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

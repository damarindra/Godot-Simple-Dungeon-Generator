extends Camera2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in 10:
		var b = SomeBug.new()
		for j in 5:
			b.array.push_back(j)
		print(b.array.size())

class SomeBug:
	var array : Array
	
	func _init():
		array = Array()
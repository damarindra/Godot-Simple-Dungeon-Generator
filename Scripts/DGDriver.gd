extends TileMap

export(NodePath) var dungeon_generator_path
export var pixel_per_unit = 16
export(Resource) var tileset
var dungeon_generator

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	dungeon_generator = get_node(dungeon_generator_path)
	dungeon_generator.do_generation()
	do_draw_map()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		for c in get_child_count():
			get_child(c).queue_free()
		dungeon_generator.do_generation()
		do_draw_map()
	

func do_draw_map():
	var t : TileMap = TileMap.new()
	t.cell_size = Vector2(pixel_per_unit, pixel_per_unit)
	t.tile_set = tileset
	add_child(t)
	for r in dungeon_generator.room_list:
		var x = 0
		while x < r.width - 0:
			var y = 0
			while y < r.height - 0:
				var v = Vector2(r.position.x + x, r.position.y + y)
				t.set_cell(v.x, v.y, tile_set.find_tile_by_name("Tile1"))
				t.update_bitmask_area(v)
				y += 1
			
			x += 1
	
	for c in dungeon_generator.corridors:
		for x in abs(c.size.x):
			for y in abs(c.size.y):
				var v = Vector2(c.position.x + x * sign(c.size.x), c.position.y + y * sign(c.size.y))
				t.set_cell(v.x, v.y, tile_set.find_tile_by_name("Tile1"))
				t.update_bitmask_area(v)
		



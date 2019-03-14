extends Control

class_name DungeonGenerator

export var debug = false
export var room_count = 20
export var min_room_size = 8
export var max_room_size = 20
export var spread_radius = 10
export var cull_ratio = 0.7
export var shrink_room_size = 1
export var non_shrink_room_chance = 0.5
export var keep_connection = 0.1

var room_list : Array = []
var verts : Array = []
var edges : Array = []
var tris : Array = []
# array of edges
var spanning_tree : Array = []
var corridors : Array = []

const Delaunay = preload("res://Scripts/Delaunay.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if debug:
		do_generation()

func _draw():
	if !debug:
		return
	for r in room_list:
		draw_rect(r.rect, Color.red, false)
	
	for s in spanning_tree:
		draw_line(s.p1, s.p2, Color.blue, 1, false)
	
	for c in corridors:
		draw_rect(c, Color.yellow, false)

func _process(delta):
	if !debug:
		return
	update()
	
	if Input.is_action_just_pressed("ui_accept"):
		do_generation()

func do_generation():
	create_rooms()
	separate_rooms()
	cull_rooms()
	connect_rooms()
	create_corridors()

func create_rooms():
	room_list.clear()
	
	for i in room_count:
		var _r : Room = Room.new()
		_r.random_size(min_room_size , max_room_size )
		_r.random_position(spread_radius )
		_r.round_position()
		room_list.push_back(_r)
	
	room_list.sort_custom(self, "sort_rooms_from_position")
	
	for r in room_count:
		room_list[r].round_position()

func separate_rooms():
	var is_intersection = true
	while is_intersection:
		is_intersection = false
		for i in room_list.size():
			var r1 = room_list[i]
			var j = i + 1
			
			while j < room_list.size():
				var r2 = room_list[j]
				if r1.rect.intersects(r2.rect):
					is_intersection = true
					var s_r1_x = round((r2.x + r2.width) - r1.x)
					var s_r2_x = round((r1.x + r1.width) - r2.x)
					
					var s_r1_y = round((r2.y + r2.height) - r1.y)
					var s_r2_y = round((r1.y + r1.height) - r2.y)
					
					if s_r1_x < s_r2_x:
						if s_r1_x < s_r1_y:
							r1.shift(s_r1_x, 0)
						else:
							r1.shift(0, s_r1_y)
					else:
						if s_r2_x < s_r2_y:
							r2.shift(s_r2_x, 0)
						else: r2.shift(0, s_r2_y)
				
				j+=1

func cull_rooms():
	room_list.sort_custom(self, "sort_room_from_size")
	var remove_count = floor(room_list.size() * cull_ratio)
	for i in remove_count:
		room_list.remove(0)
	
	room_list.sort_custom(self, "sort_rooms_from_position")
	
	for r in room_list:
		if randf() > non_shrink_room_chance:
			r.rect.position += Vector2(shrink_room_size, shrink_room_size)
			r.rect.size -= Vector2(shrink_room_size * 2, shrink_room_size * 2)


func connect_rooms():
	verts.clear()
	tris.clear()
	edges.clear()
	spanning_tree.clear()
	
	for r in room_list:
		verts.append(r.position + r.rect.size/2)
	
	tris = Delaunay.TriangulatePolygon(verts)
	
	for t in tris:
		var p1 = verts[t.p1]
		var p2 = verts[t.p2]
		var p3 = verts[t.p3]
		
		edges.push_back(Delaunay.Edge.new(p1, p2))
		edges.push_back(Delaunay.Edge.new(p1, p3))
		edges.push_back(Delaunay.Edge.new(p2, p3))
	
	var connection = []
	for v in verts:
		var c = RoomConnection.new(v)
		for e in edges:
			if c.position == e.p1:
				c.add_connect_room(e.p2)
			elif c.position == e.p2:
				c.add_connect_room(e.p1)
		connection.append(c)
	
	for c in connection:
		c.do_sort_connect_room()
	
	
	#array of vector2
	var pos_chosen : Array = []
	var check_connection : Array = [connection[0]]
	pos_chosen.push_back(connection[0].position)
	while check_connection.size() != connection.size():
		var closest_distance = INF
		var closest_point : Vector2 = Vector2()
		var closest_con = null
		var closest_pair : Vector2 = Vector2()
		
		for c in check_connection:
			for p in pos_chosen:
				if c.connected_room.has(p):
					c.connected_room.erase(p)
			if c.connected_room.size() != 0:
				if closest_distance > c.position.distance_to(c.connected_room[0]):
					closest_distance = c.position.distance_to(c.connected_room[0])
					closest_point = c.connected_room[0]
					closest_pair = c.position
			
		
		for _c in connection:
			if _c.position == closest_point:
				closest_con = _c
		
		if closest_con != null:
			pos_chosen.push_back(closest_point)
			check_connection.push_back(closest_con)
			spanning_tree.push_back(Delaunay.Edge.new(closest_pair, closest_point))
		else: break
	
	var con_count = 0
	for c in connection:
		con_count += c.connected_room.size()
	
	var keep_connection_count = floor(con_count * keep_connection)
	
	for c in connection:
		var closest_distance = INF
		var closest_point : Vector2 = Vector2()
		var closest_pair : Vector2 = Vector2()
		
		for p in pos_chosen:
			if c.connected_room.has(p):
				c.connected_room.erase(p)
			if c.connected_room.size() != 0:
				if closest_distance > c.position.distance_to(c.connected_room[0]):
					closest_distance = c.position.distance_to(c.connected_room[0])
					closest_point = c.connected_room[0]
					closest_pair = c.position
			
		if closest_distance != INF:
			spanning_tree.push_back(Delaunay.Edge.new(closest_pair, closest_point))

func create_corridors():
	corridors.clear()
	
	var i = 0
	while i < spanning_tree.size():
		var s = spanning_tree[i]
		var r1 = get_room_from_point(s.p1)
		var r2 = get_room_from_point(s.p2)
		
		var x_diff = round(s.p2.x - s.p1.x)
		var y_diff = round(s.p2.y - s.p1.y)
		var c = Rect2((r1.position + r1.rect.size / 2).round(), Vector2(3, 3))
		
		if r2.is_point_inside_room(Vector2(s.p1.x + x_diff, s.p1.y)):
			c.size.x = x_diff
		elif r2.is_point_inside_room(Vector2(s.p1.x, s.p1.x + y_diff)):
			c.size.y = y_diff
		else:
			c.size.x = x_diff
			var c1 = Rect2((c.end), Vector2(3,3))
			if x_diff > 0:
				c.size.x += 3
			elif x_diff < 0:
				c.position.x -= 1
			if y_diff < 0:
				c1.position.y -= 1
			elif y_diff > 0: y_diff -= 3
			c1.size.y = y_diff
			corridors.push_back(c1)
			
		corridors.push_back(c)
		i+=1
	pass

# --------------------------UTILITY REGION--------------------------
func sort_rooms_from_position(var a : Room, var b : Room) -> bool:
	if(a.rect.position.length() < b.rect.position.length()):
		return true
	return false
func sort_rooms_from_size(var a : Room, var b : Room) -> bool:
	if(a.rect.size.length() < b.rect.position.length()):
		return true
	return false
func get_room_from_point(var v : Vector2) -> Room:
	for r in room_list:
		if r.is_point_inside_room(v):
			return r
	return null

# ----------------------END UTILITY REGION -------------------------

class RoomConnection:
	var position : Vector2
	#Array Vector2
	var connected_room : Array
	#constructor
	func _init(var p : Vector2):
		position = p
		connected_room = Array()
	
	func add_connect_room(var v : Vector2):
		if !connected_room.has(v):
			connected_room.push_back(v)
	
	func do_sort_connect_room():
		var safe = false
		while !safe:
			safe = true
			var i = 0
			while i < connected_room.size() - 1:
				if position.distance_to(connected_room[i]) > position.distance_to(connected_room[i+1]):
					var temp = connected_room[i]
					connected_room[i] = connected_room[i+1]
					connected_room[i+1] = temp
					safe = false
				i+=1
	

class Room:
	var rect : Rect2 setget , get_rect
	var last_pos : Vector2
	var position : Vector2 setget , get_position
	var x : float setget set_x, get_x
	var y : float setget set_y, get_y
	var width : float setget set_width, get_width
	var height : float setget set_height, get_height

	func _init():
		pass
	
	func get_x() -> float:
		return rect.position.x
	func set_x(value) -> void:
		rect.position.x = value
	func get_y() -> float:
		return rect.position.y
	func set_y(value) -> void:
		rect.position.y = value
	func get_width() -> float:
		return rect.size.x
	func set_width(value) -> void:
		rect.size.x = value
	func get_height() -> float:
		return rect.size.y
	func set_height(value) -> void:
		rect.size.y = value
	func get_position() -> Vector2:
		return rect.position
	
	func get_rect() -> Rect2:
		return rect
		
	func is_moving() -> bool:
		var result = last_pos != rect.position
		last_pos = rect.position
		return result
	
	func random_size(var _min : int, var _max : int) -> void:
		rect.size.x = randi() % (_max - _min) + _min
		rect.size.y = randi() % (_max - _min) + _min
	
	func random_position(var _radius : float) -> void:
		rect.position = random_in_circle_unit() * _radius
	
	func round_position() -> void:
		rect.position = Vector2(round(rect.position.x), round(rect.position.y))
	
	func shift(var x : int, var y : int) -> void:
		rect.position.x += x
		rect.position.y += y
	
	func random_in_circle_unit() -> Vector2:
		var _rf = randf()
		var r = 1 * sqrt(_rf)
		var theta = _rf * 2 * PI
		var v = Vector2()
		v.x = r * cos(theta)
		v.y = r * sin(theta)
		return v
	
	func is_point_inside_room(var v : Vector2) -> bool:
		return rect.has_point(v)

class Intersection2Points:
	var l1 : Line
	var l2 : Line
	var intersection : Vector2
	
	func do_intersection(var _l1 : Line, var _l2 : Line) -> bool:
		l1 = _l1
		l2 = _l2
		var s : Line = Line.new(Vector2(), Vector2())
		s.p1.x = l1.p2.x - l1.p1.x
		s.p1.y = l1.p2.y - l1.p1.y
		s.p2.x = l2.p2.x - l2.p1.x
		s.p2.y = l2.p2.y - l2.p1.y
		
		var _s
		var _t
		var _div = (-s.p2.x * s.p1.y + s.p1.x * s.p2.y)
		if(_div == 0):
			print("Intersection resulting division by 0, that means the line is adjacent")
			intersection = Vector2()
			return false
		_s = (-s.p1.y * (l1.p1.x - l2.p1.x) + s.p1.x * (l1.p1.y - l2.p1.y)) / _div
		_t = (s.p2.x * (l1.p1.y - l2.p1.y) - s.p2.y * (l1.p1.x - l2.p1.x)) / _div
		
		if(_s >= 0 and _s <= 1 and _t >= 0 and _t <= 1):
			intersection = Vector2(l1.p1.x + (_t * s.p1.x), l1.p1.y + (_t * s.p1.y))
			return true
		
		return false
	

class Line:
	var p1 : Vector2
	var p2 : Vector2
	
	func _init(var _p1 : Vector2, var _p2 : Vector2):
		p1 = _p1
		p2 = _p2








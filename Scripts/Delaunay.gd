extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


#################  Originily from : https://github.com/TassuP/GodotStuff/blob/master/DelaunayTriangulator/Delaunay.gd 
#################  The rest is the delaunay-code #################

# classes for delaunay
class Triangle:
	var p1
	var p2
	var p3
	func _init(var point1, var point2, var point3):
		p1 = point1
		p2 = point2
		p3 = point3
class Edge:
	var p1
	var p2
	func _init(var point1, var point2):
		p1 = point1
		p2 = point2
	func Equals(var other):
		return ((p1 == other.p2) && (p2 == other.p1)) || ((p1 == other.p1) && (p2 == other.p2))


static func TriangulatePolygon(Vertices):
	var VertexCount = Vertices.size()
	var xmin = Vertices[0].x
	var ymin = Vertices[0].y
	var xmax = xmin
	var ymax = ymin
	
	var i = 0
	while(i < Vertices.size()):
		var v = Vertices[i]
		xmin = min(xmin, v.x)
		ymin = min(ymin, v.y)
		xmax = max(xmax, v.x)
		ymax = max(ymax, v.y)
		i += 1
	
	var dx = xmax - xmin
	var dy = ymax - ymin
	var dmax = max(dx,dy)
	var xmid = (xmax + xmin) * 0.5
	var ymid = (ymax + ymin) * 0.5
	
	var Expanded = Array()
	i = 0
	while(i < Vertices.size()):
		var v = Vertices[i]
		Expanded.append(Vector2(v.x, v.y))
		i += 1
	
	Expanded.append(Vector2((xmid - 2 * dmax), (ymid - dmax)))
	Expanded.append(Vector2(xmid, (ymid + 2 * dmax)))
	Expanded.append(Vector2((xmid + 2 * dmax), (ymid - dmax)))
	
	var TriangleList = Array()
	TriangleList.append(Triangle.new(VertexCount, VertexCount + 1, VertexCount + 2));
	var ii1 = 0
	while(ii1 < VertexCount):
		var Edges = Array()
		var ii2 = 0
		while(ii2 < TriangleList.size()):
			if (TriangulatePolygonSubFunc_InCircle(Expanded[ii1], Expanded[TriangleList[ii2].p1], Expanded[TriangleList[ii2].p2], Expanded[TriangleList[ii2].p3])):
				Edges.append(Edge.new(TriangleList[ii2].p1, TriangleList[ii2].p2));
				Edges.append(Edge.new(TriangleList[ii2].p2, TriangleList[ii2].p3));
				Edges.append(Edge.new(TriangleList[ii2].p3, TriangleList[ii2].p1));
				TriangleList.remove(ii2);
				ii2-=1
			ii2+=1
		
		ii2 = Edges.size()-2
		while(ii2 >= 0):
			var ii3 = Edges.size()-1
			while(ii3 >= ii2+1):
				if (Edges[ii2].Equals(Edges[ii3])):
					Edges.remove(ii3);
					Edges.remove(ii2);
					ii3-=1
				ii3-=1
			ii2-=1
			
		ii2 = 0
		while(ii2 < Edges.size()):
			TriangleList.append(Triangle.new(Edges[ii2].p1, Edges[ii2].p2, ii1))
			ii2+=1
		Edges.clear()
		ii1 += 1
		
	ii1 = TriangleList.size()-1
	while(ii1 >= 0):
		if (TriangleList[ii1].p1 >= VertexCount || TriangleList[ii1].p2 >= VertexCount || TriangleList[ii1].p3 >= VertexCount):
			TriangleList.remove(ii1);
		ii1-=1
		
	return TriangleList
	
static func TriangulatePolygonSubFunc_InCircle(p, p1, p2, p3):
	# I don't know the real epsilon in Godot, but this works
	var float_Epsilon = 0.000001
	if (abs(p1.y - p2.y) < float_Epsilon && abs(p2.y - p3.y) < float_Epsilon):
		return false
	var m1
	var m2
	var mx1
	var mx2
	var my1
	var my2
	var xc
	var yc
	if (abs(p2.y - p1.y) < float_Epsilon):
		m2 = -(p3.x - p2.x) / (p3.y - p2.y)
		mx2 = (p2.x + p3.x) * 0.5
		my2 = (p2.y + p3.y) * 0.5
		xc = (p2.x + p1.x) * 0.5
		yc = m2 * (xc - mx2) + my2
	elif (abs(p3.y - p2.y) < float_Epsilon):
		m1 = -(p2.x - p1.x) / (p2.y - p1.y)
		mx1 = (p1.x + p2.x) * 0.5
		my1 = (p1.y + p2.y) * 0.5
		xc = (p3.x + p2.x) * 0.5
		yc = m1 * (xc - mx1) + my1
	else:
		m1 = -(p2.x - p1.x) / (p2.y - p1.y)
		m2 = -(p3.x - p2.x) / (p3.y - p2.y)
		mx1 = (p1.x + p2.x) * 0.5
		mx2 = (p2.x + p3.x) * 0.5
		my1 = (p1.y + p2.y) * 0.5
		my2 = (p2.y + p3.y) * 0.5
		xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
		yc = m1 * (xc - mx1) + my1
		
	var dx = p2.x - xc
	var dy = p2.y - yc
	var rsqr = dx * dx + dy * dy
	dx = p.x - xc
	dy = p.y - yc
	var drsqr = dx * dx + dy * dy
	return (drsqr <= rsqr)



# -------------------- FAIL --------------------- 
#class Triangle:
#	var points : Array
#	var bad : bool
#	func _init(var p_a : int, var p_b : int, var p_c : int):
#		points.push_back(p_a)
#		points.push_back(p_b)
#		points.push_back(p_c)
#		bad = false
#
#class Edge:
#	var edge : Array
#	var bad
#	func _init(var p_a : int, var p_b : int):
#		bad = false
#		edge.push_back(p_a)
#		edge.push_back(p_b)
#
#static func circum_circle_contains(var verts : Array, var triangle : Triangle, var vertex : int) -> bool:
#	var p1 : Vector2 = verts[triangle.points[0]]
#	var p2 : Vector2 = verts[triangle.points[1]]
#	var p3 : Vector2 = verts[triangle.points[2]]
#
#	var ab : float = p1.x * p1.x + p1.y * p1.y
#	var cd : float = p2.x * p2.x + p2.y * p2.y
#	var ef : float = p3.x * p3.x + p3.y * p3.y
#
#	var circum = Vector2((ab * (p3.y - p2.y) + cd * (p1.y - p3.y) + ef * (p2.y - p1.y)) / (p1.x * (p3.y - p2.y) + p2.x * (p1.y - p3.y) + p3.x * (p2.y - p1.y)),
#				(ab * (p3.x - p2.x) + cd * (p1.x - p3.x) + ef * (p2.x - p1.x)) / (p1.y * (p3.x - p2.x) + p2.y * (p1.x - p3.x) + p3.y * (p2.x - p1.x)));\
#	circum *= 0.5
#
#	var r = p1.distance_squared_to(circum)
#	var d = verts[vertex].distance_squared_to(circum)
#	return d <= r
#
#static func edge_compare(var verts : Array, var p_a : Edge, var p_b : Edge, var CMP_EPSILON = 0.00001) -> bool:
#	if (verts[p_a.edge[0]].distance_to(verts[p_b.edge[0]]) < CMP_EPSILON && verts[p_a.edge[1]].distance_to(verts[p_b.edge[1]]) < CMP_EPSILON) :
#		return true
#
#	if (verts[p_a.edge[0]].distance_to(verts[p_b.edge[1]]) < CMP_EPSILON && verts[p_a.edge[1]].distance_to(verts[p_b.edge[0]]) < CMP_EPSILON):
#		return true
#	return false
#
#static func triangulate(var p_points : Array) -> Array:
#	var points : Array
#	for p in p_points:
#		points.push_back(p)
#	var triangles : Array
#
#	var rect : Rect2;
#	for i in p_points.size():
#		if (i == 0) :
#			rect.position = p_points[i]
#		else:
#			rect.expand(p_points[i])
#
#
#	var delta_max = max(rect.size.x, rect.size.y)
#	var center = rect.position + rect.size * 0.5
#
#	points.push_back(Vector2(center.x - 20 * delta_max, center.y - delta_max))
#	points.push_back(Vector2(center.x, center.y + 20 * delta_max))
#	points.push_back(Vector2(center.x + 20 * delta_max, center.y - delta_max))
#
#	triangles.push_back(Triangle.new(p_points.size() + 0, p_points.size() + 1, p_points.size() + 2))
#
#	for i in p_points.size():
#		var polygon : Array
#
#		for j in triangles.size():
#			if (circum_circle_contains(points, triangles[j], i)):
#				triangles[j].bad = true
#				polygon.push_back(Edge.new(triangles[j].points[0], triangles[j].points[1]))
#				polygon.push_back(Edge.new(triangles[j].points[1], triangles[j].points[2]))
#				polygon.push_back(Edge.new(triangles[j].points[2], triangles[j].points[0]))
#
#
#		for j in triangles.size():
#			if (triangles[j].bad):
#				triangles.remove(j)
#				j-=1
#
#		for j in polygon.size():
#			var k = j + 1
#			while k < polygon.size():
#				if (edge_compare(points, polygon[j], polygon[k])):
#					polygon[j].bad = true
#					polygon[k].bad = true
#				k+=1
#
#		for j in polygon.size():
#			if (polygon[j].bad) :
#				continue
#			triangles.push_back(Triangle.new(polygon[j].edge[0], polygon[j].edge[1], i))
#
#
#	for i in triangles.size():
#		var invalid = false
#		for j in 3:
#			if (triangles[i].points[j] >= p_points.size()) :
#				invalid = true;
#				break;
#		if (invalid):
#			triangles.remove(i)
#			i-=1
#
#	return triangles;



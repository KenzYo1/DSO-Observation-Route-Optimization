extends Node2D

var font = ThemeDB.fallback_font
const vertex = preload("res://vertex.tscn")

class adj_matrix:
	var buffer: Array[Array] 
	var n: int
	
class held_karp_el:
	var path: Array
	var totalWeight: float
	
var verticesCoords: Array[Vector2] = []
var dist_adj_matrix = adj_matrix.new()
var original_dist_adj_matrix = adj_matrix.new() # matrix for storing original distance before priority
var shortest_path_list: Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_dist_adj_matrix(dist_adj_matrix, SharedValues.stackOfObject.TOP+1)
	create_dist_adj_matrix(original_dist_adj_matrix, SharedValues.stackOfObject.TOP+1)
	gen_k_graph()
	
# we take the values from the stack at SharedValue, then use it to build an adjacency matrix
func create_dist_adj_matrix(matrix: adj_matrix, n: int) -> void:
	matrix.n = n
	
	var stackBuf = SharedValues.stackOfObject.stackBuffer
	
	var smallestObj = stackBuf[0].priority
	var smallestIdx = 0
	for i in range(1,n):
		if smallestObj < stackBuf[i].priority:
			smallestObj = stackBuf[i].priority
			smallestIdx = i
	var temp = stackBuf[0]
	stackBuf[0] = stackBuf[smallestIdx]
	stackBuf[smallestIdx] = temp
	
	for i in range(n):
		matrix.buffer.append([])
		matrix.buffer[i].resize(n)

	for i in range(n):
		var first_node = SharedValues.stackOfObject.stackBuffer[i]
		for j in range(i, n):
			if i == j: 
				matrix.buffer[i][j] = 0
				continue
			var other_node = SharedValues.stackOfObject.stackBuffer[j]

			var dist = (
				sin(deg_to_rad(first_node.declination)) * sin(deg_to_rad(other_node.declination)) +
				cos(deg_to_rad(first_node.declination)) * cos(deg_to_rad(other_node.declination)) *
				cos(deg_to_rad(first_node.right_ascension - other_node.right_ascension))
			)
			dist = clamp(dist, -1.0, 1.0) # catch if floating point error 
			dist = acos(dist)
			if first_node.priority > 0 and matrix != original_dist_adj_matrix: # shorten distances if the node has a priority
				dist *= (1-first_node.priority)
			matrix.buffer[i][j] = dist
			matrix.buffer[j][i] = dist


func convert_celestial_coords_to_xy(celest_coord: SharedValues.StackEl) -> Vector2:
	var x = 9600 - celest_coord.right_ascension / 360.0 * 9600 # screen width - because star charts are mirrored
	var y = (1.0 - (celest_coord.declination + 90.0) / 180.0) * 5400
	return Vector2(x,y)


var draw_main_line = true
var draw_found_path = false
func _draw() -> void:
	if draw_main_line:
		for i in range(len(verticesCoords)):
			var currObj = verticesCoords[i]
			for j in range(i, len(verticesCoords)):
				if i == j: continue
				draw_line(currObj, verticesCoords[j], "blue")
				draw_string(
					font, 
					(currObj + verticesCoords[j]) / 2.0,
					"%.3f" % (original_dist_adj_matrix.buffer[i][j]),
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					10
				)
	elif draw_found_path:
		for i in range(len(verticesCoords) - 1):
			draw_line(
				verticesCoords[shortest_path_list[i]],
				verticesCoords[shortest_path_list[i+1]],
				"red",
				1.5
			)
			draw_string(
				font,
				(verticesCoords[shortest_path_list[i]] + verticesCoords[shortest_path_list[i+1]]) / 2,
				"%.3f" % (original_dist_adj_matrix.buffer[shortest_path_list[i]][shortest_path_list[i+1]])
			)

func gen_k_graph() -> void:
	var stackBuf = SharedValues.stackOfObject.stackBuffer
	for i in range(SharedValues.stackOfObject.TOP+1):
		verticesCoords.append(convert_celestial_coords_to_xy(stackBuf[i]))
		
		var newObjNode = vertex.instantiate()
		var nodeName = newObjNode.get_node("VBoxContainer/Name")
		var nodePriority = newObjNode.get_node("VBoxContainer/MainVertex/Priority")
		nodeName.text = stackBuf[i].objName
		nodePriority.text = str(stackBuf[i].priority) if stackBuf[i].priority > 0 else ""
		newObjNode.position = verticesCoords[i]
		add_child(newObjNode)
		
	queue_redraw()
	
func held_karp_algo() -> held_karp_el:
	var n = dist_adj_matrix.n
	
	var nSubsets = 1 << n
	var dp: Array[Array] = []
	# to traceback the path, we need a parent matrix
	var parent: Array[Array] = []
	
	for i in range(nSubsets):
		dp.append([])
		dp[i].resize(n)
		for j in range(n):
			dp[i][j] = INF
			
	for i in range(nSubsets):
		parent.append([])
		parent[i].resize(n)
		for j in range(n):
			parent[i][j] = null
	
	dp[1][0] = 0
	
	for mask in range(1, nSubsets):
		if not (mask & 1):
			continue
		for j in range(1, n):
			if not (mask & (1 << j)):
				continue
			var prevMask = mask ^ (1 << j)
			
			for k in range(n):
				if prevMask & (1 << k):
					var cost = dp[prevMask][k] + dist_adj_matrix.buffer[k][j]
					if cost < dp[mask][j]:
						dp[mask][j] = cost
						parent[mask][j] = k
						
	
	# because this is to find the shortest hamiltonian path, we need not return to the first node
	var fullMask = (1 << n) - 1
	var answer = INF
	var endNode = -1
	
	for j in range(n):
		if dp[fullMask][j] < answer:
			answer = dp[fullMask][j]
			endNode = j
	
	var path: Array = []
	var mask = fullMask
	var prev
	var curr = endNode
	while curr != null:
		path.append(curr)
		prev = parent[mask][curr]
		mask ^= (1 << curr)
		curr = prev

	path.reverse()
	var retEl = held_karp_el.new()
	retEl.path = path
	retEl.totalWeight = answer
	return retEl

func find_shortest_path() -> void:
	var retEl = held_karp_algo()
	shortest_path_list = retEl.path
	var dist = 0
	for i in range(len(retEl.path) - 1):
		dist += original_dist_adj_matrix.buffer[retEl.path[i]][retEl.path[i+1]]
	SharedValues.totalWeight = dist
	SharedValues.path = retEl.path
	draw_found_path = true
	draw_main_line = false
	queue_redraw()
	
func gen_random_paths(n: int, priority: bool) -> void:
	var total_dist = 0
	var path = []
	var best = INF
	var worst = 0.0
	if not priority:
		for i in range(n):
			path.append(i)

		for h in range(1000):
			path.shuffle()
			var currDist = 0.0
			for i in range(n - 1):
				currDist += original_dist_adj_matrix.buffer[path[i]][path[i+1]]
			total_dist += currDist
			best = min(best, currDist)
			worst = max(worst, currDist)
	
	else:
		var first_array = []
		var nPriorities = 0
		for i in range(n):
			if SharedValues.stackOfObject.stackBuffer[i].priority > 0:
				first_array.append(i)
				nPriorities += 1
			else:
				path.append(i)
		
		first_array.sort_custom(func(a,b): return (
				SharedValues.stackOfObject.stackBuffer[a].priority > 
				SharedValues.stackOfObject.stackBuffer[b].priority
				)
			)
		for h in range(1000):
			path.shuffle()
			var toCalculate = []
			for i in range(nPriorities):
				toCalculate.append(first_array[i])
			for i in range(n - len(first_array)):
				toCalculate.append(path[i])
			var currDist = 0
			for i in range(n - 1):
				currDist += original_dist_adj_matrix.buffer[toCalculate[i]][toCalculate[i+1]]
			total_dist += currDist
			best = min(best, currDist)
			worst = max(worst, currDist)
		
	total_dist /= 1000.0
	print("Average cost: ", total_dist)
	print("Best cost: ", best)
	print("Worst cost: ", worst)

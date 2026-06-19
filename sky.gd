extends Node2D

@onready var tipLabel: Label = $Camera2D/CanvasLayer/Label
@onready var fileErrLabel: Label = $Camera2D/CanvasLayer/FileErrorLabel
@onready var generationLabel: Label = $Camera2D/CanvasLayer/GenerationDone
@onready var graphWeight: Label = $Camera2D/CanvasLayer/graphWeight
@onready var shortestPath: Label = $Camera2D/CanvasLayer/shortestPath

const graphGenNode = preload("res://graph_gen.tscn")
var k_graph = null

const CSV_FILE = "res://deep_space_objects//dso.csv"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parse_csv(CSV_FILE)
	fileErrLabel.visible = SharedValues.isEmpty(SharedValues.stackOfObject)

func _process(delta):
	if Input.is_action_just_pressed("openTip"):
		tipLabel.visible = (not tipLabel.visible)
		
	elif Input.is_action_just_pressed("generateKGraph"):
		k_graph = graphGenNode.instantiate()
		generationLabel.visible = true
		add_child(k_graph)
		await get_tree().create_timer(2.0).timeout
		generationLabel.visible = false
		graphWeight.visible = false
		shortestPath.visible = false
		
	elif Input.is_action_just_pressed("findShortestPath"):
		if k_graph == null:
			return
		k_graph.find_shortest_path()
		graphWeight.text = "Total Weight: %.2f" % SharedValues.totalWeight
		graphWeight.visible = true
		var pathStr = "Shortest Hamiltonian Path: "
		for i in range(SharedValues.stackOfObject.TOP + 1):
			pathStr += str(SharedValues.stackOfObject.stackBuffer[SharedValues.path[i]].objName)
			if i != SharedValues.stackOfObject.TOP:
				pathStr += " -> "
		shortestPath.text = pathStr
		shortestPath.visible = true
		print(pathStr)
		
		k_graph.gen_random_paths(SharedValues.stackOfObject.TOP+1, true)

		
func change_file_err_msg(msg: String) -> void:
	fileErrLabel.text = msg


func ra_to_deg(ra: String) -> float:
	var p = ra.split(":")
	var h = float(p[0])
	var m = float(p[1])
	var s = float(p[2])
	
	return 15.0 * (h + m/60.0 + s/3600.0)

func csv_deg_to_float_deg(d: String) -> float:
	var p = d.split(":")
	var h = float(p[0])
	var m = float(p[1])
	var s = float(p[2])

	return (
		h + (m/60.0 + s/3600.0) * (1 if h > 0 else -1)
	)

func add_to_stack(csv_row) -> void:
	if len(csv_row) != 4:
		return
	var newStackEl = SharedValues.StackEl.new()
	newStackEl.objName = csv_row[0]
	newStackEl.right_ascension = ra_to_deg(csv_row[1])
	newStackEl.declination = csv_deg_to_float_deg(csv_row[2])
	newStackEl.priority = float(csv_row[3])
	SharedValues.pushStack(SharedValues.stackOfObject, newStackEl)


func parse_csv(file_name) -> void:
	var i = 0
	var file = FileAccess.open(file_name, FileAccess.READ)
	while not file.eof_reached():
		var row = file.get_csv_line()
		if i == 0: i += 1; continue
		add_to_stack(row)
		i += 1
		

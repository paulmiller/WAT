extends Reference
class_name WATDouble

# Controllers
const TOKENIZER = preload("res://addons/WAT/double/tokenizer.gd")
const REWRITER = preload("res://addons/WAT/double/rewriter.gd")
const IO = preload("res://addons/WAT/double/input_output.gd")

# Data Structures
const BLANK: Script = preload("res://addons/WAT/double/blank.gd")
const SCRIPT_DATA = preload("res://addons/WAT/double/script_data.gd")
const SCENE_DATA = preload("res://addons/WAT/double/scene_data.gd")



static func script(gdscript) -> SCRIPT_DATA:
	var script: Script = IO.load_script(gdscript)
	var tokens = TOKENIZER.start(script)
	var rewrite: String = REWRITER.start(tokens)
	IO.save_script(tokens.title, rewrite)
	return SCRIPT_DATA.new(tokens.methods, IO.load_doubled_script(tokens.title))

static func scene(tscn) -> SCENE_DATA:
	var scene = IO.load_scene_instance(tscn)
	var path: String = IO.TEMP_DIR_PATH + IO.SCENE_DIR_PATH % scene.name
	var outline: Array = _get_tree_outline(path, scene)
	var doubled: Node = _create_scene_double(outline, scene.name)
	IO.save_scene(doubled, path, scene.name)
	return SCENE_DATA.new(outline, doubled)

static func _get_tree_outline(scene_path: String, scene: Node) -> Array:
	# SEPERATE METHOD
	var outline: Array = []
	var frontier: Array = [scene]
	while not frontier.empty():
		var node = frontier.pop_front()
		frontier += node.get_children()
		var path = scene.get_path_to(node)
		var data = {"nodepath": path, "scriptpath": null, "methods": null}
		
		# We need to create a NEW TREE, rather than anything else. Duplicating will not work.
		if _has_custom_script(node):
			var script: Script = node.script
			var tokens = TOKENIZER.start(script)
			var rewrite: String = REWRITER.start(tokens)
			IO.save_script(tokens.title, rewrite, scene_path)
			data.scriptpath = IO.SCRIPT_PATH % [scene_path, tokens.title]
			data.methods = tokens.methods
		outline.append(data)
	return outline

static func _create_scene_double(paths: Array, name) -> Node:
	var root = Node # May cause issues later
	for i in paths:
		var node: Node = _create_node(i)
		var split_node_path: Array = split_nodepath(i.nodepath)
		if _is_scene_root(split_node_path):
			root = node
			root.name = name
			continue # Unnecessary?
		if _is_child_of_root(split_node_path):
			node.name = split_node_path[0]
			root.add_child(node)
		else:
			# Adding Subchildren
			_add_grandchildren(split_node_path, node, root)
#			var main_node = split_node_path.pop_back()
#			var parent_node = split_node_path.pop_back()
#			node.name = main_node
#			root.get_node(parent_node).add_child(node)
		# Setting all owners to root for saving
		node.owner = root
	return root

static func _has_custom_script(node: Node) -> bool:
	return node.script != null
	
static func _create_node(data: Dictionary) -> Node:
	return load(data.scriptpath).new() if data.scriptpath != null else Node.new()
	
static func split_nodepath(nodepath: String) -> Array:
	return Array(nodepath.split("/"))
	
static func _is_scene_root(node: Array) -> bool:
	return node[0] == "." and node.size() == 1
	
static func _is_child_of_root(node) -> bool:
	return node.size() == 1
		
static func _add_grandchildren(split_node_path: Array, node: Node, root: Node) -> void:
	var grandchild_name = split_node_path.pop_back()
	var child_name = split_node_path.pop_back()
	node.name = grandchild_name
	root.get_node(child_name).add_child(node)
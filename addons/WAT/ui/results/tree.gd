tool
extends Tree

const ScriptTreeItem: GDScript = preload("res://addons/WAT/ui/results/script.gd")
const MethodTreeItem: GDScript = preload("res://addons/WAT/ui/results/method.gd")
const AssertionTreeItem: GDScript = preload("res://addons/WAT/ui/results/assertion.gd")

var tests = []
var root: TreeItem
var scripts: Dictionary = {}
var current_method: MethodTreeItem
var icons: Reference
var failed: bool = false
var goto_function: FuncRef

func _init(_icons: Reference) -> void:
	icons = _icons
	if Engine.is_editor_hint():
		connect("button_pressed", self, "_on_button_pressed")
	
func _on_button_pressed(item: TreeItem, col: int = 0, id: int = 0) -> void:
	var data: MethodTreeItem = item.get_meta("data")
	goto_function.call_func(data.scriptpath, data.name)

func _ready() -> void:
	visible = false
	hide_root = true
	root = create_item()
	add_constant_override("Scroll Speed", 24)
	
const PASSED: Color = Color(0.34375, 1, 0.34375)
const FAILED: Color = Color(1, 0.425781, 0.425781)

func add_result(result) -> void:
	var script: ScriptTreeItem = scripts[result["path"]]
	var success: bool = result["success"]
	script.component.set_custom_color(0, PASSED if success else FAILED)
	script.component.set_icon(0, icons.passed if success else icons.failed)
	failed = not success
	scroll_to_item(root)

# TODO: All of these dict values should be serialized and unserialized at server points
# ..or sent directly if run in the editor but point is objects > dicts
func add_test(test) -> void:
	var script: ScriptTreeItem = ScriptTreeItem.new(create_item(root), test)
	scripts[script.path] = script
	# Scrolling to a Script Component hides the scroll bar so don't

func add_method(data: Dictionary) -> void:
	var script: ScriptTreeItem = scripts[data["path"]]
	script.add_method(self, data)
	var method: MethodTreeItem = script.methods.values().back()
	if Engine.is_editor_hint():
		method.component.add_button(0, icons.function)
		method.component.set_tooltip(0, "Click function icon to show test method in editor")
		method.component.set_meta("data", method)

func add_assertion(data: Dictionary) -> void:
	var script: ScriptTreeItem = scripts[data["path"]]
	var method: MethodTreeItem = script.methods[data["method"]]
	method.add_assertion(self, data)
	if not data["assertion"]["success"]:
		script.component.set_custom_color(0, FAILED)
		script.component.set_icon(0, icons.failed)
		method.component.set_custom_color(0, FAILED)
		method.component.set_icon(0, icons.failed)
		failed = true
	
func on_test_method_described(data: Dictionary) -> void:
	scripts[data["path"]].methods[data["method"]].component.set_text(0, data["description"])
	
func on_test_script_finished(data: Dictionary) -> void:
	# On a finished test, change its color
	var script: ScriptTreeItem = scripts[data["path"]]
	var success: bool = data["success"]
	script.component.set_custom_color(0, PASSED if success else FAILED)
	script.component.set_icon(0, icons.passed if success else icons.failed)
	
func on_test_method_finished(data: Dictionary) -> void:
	# On a finished method, change its color
	var script: ScriptTreeItem = scripts[data["path"]]
	var method: MethodTreeItem = script.methods[data["method"]]
	script.on_method_finished(data)
	if not data["success"]:
		script.component.set_custom_color(0, FAILED)
		script.component.set_icon(0, icons.failed)
		failed = true
	method.component.set_custom_color(0, PASSED if data["success"] else FAILED)
	method.component.set_icon(0, icons.passed if data["success"] else icons.failed)
	method.component.collapsed = true
	scroll_to_item(method.component)


#	scroll_to_item(assertion_item)
#
#class ScriptTreeItem:
#	var instance: TreeItem
#	var methods: Array = [] # TreeItems
#
#	func _init():
#		pass

#var FUNCTION
#var PASSED_ICON
#var FAILED_ICON
#const PASSED: Color = Color(0.34375, 1, 0.34375)
#const FAILED: Color = Color(1, 0.425781, 0.425781)
#signal calculated
#var _parent: TabContainer
#var _results: Array = []
#var _failures: Array = []
#
#func _init(parent: TabContainer) -> void:
#	_parent = parent
#
#func _ready():
#	hide_root = true
#
#func display(cases: Array) -> void:
#	var total = cases.size()
#	var passed = 0
#	var root = create_item()
#
#	for c in cases:
#		passed += c.success as int
#		var script = create_item(root)
#		script.set_text(0, "(%s/%s) %s" % [c.passed, c.total, c.context])
#		script.set_custom_color(0, _color(c.success))
#		script.set_icon(0, _icon(c.success))
#		_results.append(script)
#		if not c.success:
#			_failures.append(script)
#
#		_results.append(script)
#
#		for m in c.methods:
#			var method = create_item(script)
#			method.set_text(0, "%s" % m.context)
#			method.set_custom_color(0, _color(m.success))
#			method.set_icon(0, _icon(m.success))
#			if Engine.is_editor_hint():
#				method.add_button(0, FUNCTION)
#			method.set_tooltip(0, "Click icon to show test method in editor")
#			method.set_meta("path", c.path)
#			method.set_meta("context", m.context)
#			method.set_meta("fullname", m.fullname)
#			_results.append(method)
#			if not m.success:
#				_failures.append(method)
#
#			for a in m.assertions:
#				if a.context != "":
#					method.collapsed = false
#					var assertion = create_item(method)
#					assertion.set_text(0, a.context)
#					assertion.set_custom_color(0, _color(a.success))
#					assertion.set_icon(0, _icon(a.success))
#					assertion.collapsed = true
#					var expected = create_item(assertion)
#					var actual = create_item(assertion)
#					expected.set_text(0, "EXPECTED: %s" % a.expected)
#					actual.set_text(0, "RESULTED: %s" % a.actual)
#					if not a.success:
#						_failures.append(assertion)
#				else:
#					method.collapsed = true
#					var expected = create_item(method)
#					var actual = create_item(method)
#					expected.set_text(0, "EXPECTED: %s" % a.expected)
#					actual.set_text(0, "RESULTED: %s" % a.actual)
#
#
#	var success = total > 0 and total == passed
#	root.set_text(0, "%s/%s" % [passed, total])
#	root.set_custom_color(0, _color(success))
#	root.set_icon(0, _icon(success))
#
#	name += " (%s|%s)" % [passed, total]
#	_parent.set_tab_icon(get_index(), _icon(success))
#
#func _color(success: bool) -> Color:
#	return PASSED if success else FAILED
#
#func _icon(success: bool) -> Texture:
#	return PASSED_ICON if success else FAILED_ICON
#
#func expand_all():
#	for item in _results:
#		item.collapsed = false
#
#func collapse_all():
#	for item in _results:
#		item.collapsed = true
#
#func expand_failures():
#	collapse_all()
#	for item in _failures:
#		item.collapsed = false
#
#func _setup_editor_assets(assets_registry):
#	FUNCTION = assets_registry.load_asset("assets/function.png")
#	PASSED_ICON = assets_registry.load_asset("assets/passed.png")
#	FAILED_ICON = assets_registry.load_asset("assets/failed.png")
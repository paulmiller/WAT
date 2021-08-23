extends Node


var _current_method: String = ""
var _dir: String = ""
var _path: String

signal results_received
var results: Node # either server or results tree

signal test_method_started
signal asserted
signal test_method_finished

func run(metadata: Dictionary) -> void:
	_dir = metadata["dir"]
	_path = metadata["path"]
	var methods = metadata["methods"]
	var test: Node = load(_path).new().setup(_dir, _path, methods)
	
	test.connect("test_method_started", self, "on_test_method_started")
	test.connect("asserted", self, "_on_asserted")
	test.connect("test_method_finished", self, "on_test_method_finished")

	# We need to wait for the object itself to emit the signal (since we..
	# ..cannot yield for C# so we defer the call to run so we have time to..
	# ..to setup our yielding rather than deal with a race condition)
	results.on_test_script_started(metadata)
	call_deferred("add_child", test)
	var results = yield(self, "results_received") # test_script_finished
	test.queue_free()
	return results

# Results broker doesn't make any sense
func get_results(data) -> void:
	# Called by Tests as our children
	
	results.on_test_script_finished(data)
	emit_signal("results_received", data)
	
func on_test_method_started(method) -> void:
	var x = {"dir" : _dir, "path": _path, "method": method}
	#emit_signal("method_started", x) # What about "described" methods?
	results.on_test_method_started(x)
	_current_method = method

func on_test_method_finished(method) -> void:
	var count = method["total"]
	var passed = method["passed"]
	var success = count > 0 and count == passed
	var x = {"dir": _dir, "path": _path, "method": _current_method, "success": success, "total": count, "passed": passed}
	results.on_test_method_finished(x)
	
func _on_asserted(assertion) -> void:
	var x = {"dir" : _dir, "path": _path, "method": _current_method, "assertion": assertion}
	results.on_asserted(x) #emit_signal("asserted", x)

#func on_method_described(desc: String) -> void:
#	var x = {"dir" : _dir, "path": _path, "method": _current_method, "description": desc}
#	get_parent().emit_signal("method_described", x)

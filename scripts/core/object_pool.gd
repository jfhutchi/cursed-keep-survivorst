class_name ObjectPool
extends RefCounted
## Generic node pool. Pooled nodes must implement:
##   _pool_activate()    - called when taken from the pool
##   _pool_deactivate()  - called when returned to the pool
## Nodes stay in the tree (hidden, processing off) to avoid add/remove churn.

var _scene: PackedScene
var _script_type: GDScript
var _parent: Node
var _free: Array[Node] = []
var active: Array[Node] = []


func _init(parent: Node, scene: PackedScene = null, script_type: GDScript = null) -> void:
	_parent = parent
	_scene = scene
	_script_type = script_type


func _create() -> Node:
	var node: Node
	if _scene != null:
		node = _scene.instantiate()
	else:
		node = Node2D.new()
		node.set_script(_script_type)
	_parent.add_child(node)
	return node


func acquire() -> Node:
	var node: Node = _free.pop_back() if not _free.is_empty() else _create()
	active.append(node)
	if node.has_method("_pool_activate"):
		node._pool_activate()
	return node


func release(node: Node) -> void:
	var idx := active.find(node)
	if idx < 0:
		return # already released
	active.remove_at(idx)
	_free.append(node)
	if node.has_method("_pool_deactivate"):
		node._pool_deactivate()


func release_all() -> void:
	while not active.is_empty():
		release(active[active.size() - 1])


func active_count() -> int:
	return active.size()

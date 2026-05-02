extends Node

# Generic node pooling for short-lived scene instances.

# Keep pools bounded so leaks do not turn into long-term memory growth.
@export var max_free_nodes_per_scene := 28
@export var max_total_free_nodes := 180
var _pools: Dictionary = {}
var _pool_owner: Node


func _ready() -> void:
	_pool_owner = get_tree().root


func set_pool_owner(owner: Node) -> void:
	_pool_owner = owner


func acquire(scene_path: String) -> Node:
	if not ResourceLoader.exists(scene_path):
		return null

	var entry: Dictionary = _pools.get(scene_path, {})
	if entry.is_empty():
		entry["scene"] = load(scene_path)
		entry["free"] = []
		_pools[scene_path] = entry

	var node: Node = null
	var free_list: Array = entry["free"] as Array
	if free_list.size() > 0:
		node = free_list.pop_back() as Node
	else:
		node = (entry["scene"] as PackedScene).instantiate()

	if node.get_parent():
		node.get_parent().remove_child(node)
	if _pool_owner:
		_pool_owner.add_child(node)

	if node.has_method("on_spawn"):
		node.on_spawn()
	node.visible = true
	node.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
	node.set_process(true)
	return node


func release(scene_path: String, node: Node) -> void:
	if node == null:
		return
	if not _pools.has(scene_path):
		node.queue_free()
		return

	var entry: Dictionary = _pools[scene_path]
	var free_list: Array = entry["free"] as Array
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.visible = false
	node.set_process(false)
	node.set_process_mode(Node.PROCESS_MODE_DISABLED)
	if node.has_method("on_released"):
		node.on_released()

	if not free_list.has(node):
		free_list.append(node)
		if free_list.size() > max_free_nodes_per_scene:
			var overflow_node = free_list.pop_front()
			if overflow_node and is_instance_valid(overflow_node):
				overflow_node.queue_free()
		_enforce_global_pool_limit()
	entry["free"] = free_list


func _enforce_global_pool_limit() -> void:
	var total_free = 0
	for key in _pools.keys():
		var entry = _pools[key]
		var free_list: Array = entry["free"] as Array
		total_free += free_list.size()

	if total_free <= max_total_free_nodes:
		return

	var to_drop = total_free - max_total_free_nodes
	for key in _pools.keys():
		if to_drop <= 0:
			break
		var entry = _pools[key]
		var free_list: Array = entry["free"] as Array
		while to_drop > 0 and free_list.size() > 0:
			var overflow_node = free_list.pop_front()
			to_drop -= 1
			if overflow_node and is_instance_valid(overflow_node):
				overflow_node.queue_free()
		entry["free"] = free_list


func clear_pool() -> void:
	for key in _pools.keys():
		var entry = _pools[key]
		var free_list: Array = entry["free"] as Array
		for node in free_list:
			if is_instance_valid(node):
				node.queue_free()
		entry["free"] = []

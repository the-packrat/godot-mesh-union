@tool
extends EditorPlugin

var dock:Control

func _enter_tree() -> void:
	# load dock scene and instantiate
	dock = preload("res://addons/mesh_union/mesh_union.tscn").instantiate()
	
	# add loaded scene to the docks
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	return

func _exit_tree() -> void:
	# remove the dock
	remove_control_from_docks(dock)
	
	# erase from memory
	dock.free()
	return

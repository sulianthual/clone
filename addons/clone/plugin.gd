@tool
extends EditorPlugin

## Plugin Setup for Clone (sul 2025)

var dock
func _enter_tree():
	# Initialization of the plugin goes here.
	dock=preload("res://addons/clone/clone_menu.tscn").instantiate()
	#add_control_to_dock(DOCK_SLOT_RIGHT_BL,dock)
	add_control_to_bottom_panel(dock, "Clone")

func _exit_tree():
	# Clean-up of the plugin goes here.
	#remove_control_from_docks(dock)
	remove_control_from_bottom_panel(dock)
	dock.free()

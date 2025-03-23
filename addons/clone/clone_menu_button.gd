@tool
extends Button

## Button that opens the cloning launcher (in Inspector)
## Also displays a few messages, and resets cloning launcher at ready

var cloning_launcher: Resource=preload("res://addons/clone/cloning_launcher.tres")
var cloning_launcher_script: Script=preload("res://addons/clone/cloning_launcher.gd")
var last_cloning_folder: String
#@onready var timer: Timer=Timer.new()
@onready var timer: Timer = %Timer
func _ready() -> void:
	## RESET CLONING LAUNCHER
	cloning_launcher.set_script(cloning_launcher_script)# in case was removed
	## SETUP
	connect("pressed",_on_pressed)
	timer.connect("timeout",_on_timer_timeout)
	cloning_launcher.connect("cloning",_on_cloning)
	connect("tree_exiting",_on_tree_exiting)
	set_text_default()
func _on_pressed():
	open_clone_interface()
func _on_cloning(output_folder: String):
	text="Cloning to "+output_folder+" ..."
	last_cloning_folder=output_folder
	timer.start()
func _on_timer_timeout():
	set_text_default_lastclone()
func set_text_default():
	text="Drop PackedScene here then launch Cloning from Inspector"
func set_text_default_lastclone():
	text="Drop PackedScene here then launch Cloning from Inspector\nLast Cloning to "+last_cloning_folder
func _on_tree_exiting():
	if cloning_launcher:
		cloning_launcher.packedscene=null

func _can_drop_data(position, data):
	#print("_can_drop_data: ",typeof(data),":",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="tscn":
			return true
	return false
	
signal data_dropped(value: String)# return the png file
func _drop_data(position, data):
	#print("_drop_data: ",data)
	if typeof(data) == TYPE_DICTIONARY:
		if data.type=="files" and data.files[0].get_extension()=="tscn":
			data_dropped.emit(data.files[0])
			cloning_launcher.packedscene=load(data.files[0])
			open_clone_interface()
func open_clone_interface():
	EditorInterface.edit_resource(cloning_launcher)
	

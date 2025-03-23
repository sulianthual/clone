@tool
extends Resource

## Clone a PackedScene to a new folder and remove (most) dependencies to original. 
## The cloned PackedScene can be modified without modifying the original (akin to forking). 
## BEWARE not all dependencies are removed automatically, see instructions. 

##########################################################################
## EXPORTS

## PackedScene to Clone. 
## After cloning most dependencies to original scene are removed (but not all).
@export var packedscene: PackedScene

## Launch cloning. 
@export_tool_button("Launch","Callable") var launch=launch_function

@export_subgroup("Options")
## Folder where packedscene and all dependencies are cloned. 
## Beware all content will be overwritten (if clear_output=true). 
## If empty defaults to clone_test/ for input path ".../test.tscn".
@export_dir var output_folder:  String=""
## Prefix added to all cloned filenames. 
@export_dir var output_prefix:  String="clone_"
## If true, clear output folder before duplication
@export var clear_output: bool=true
## Copy scripts of original node and all descendants to output folder/scripts. 
## Subfolder structure mirrors original from res:// (to avoid duplicate filenames). 
@export var copy_scripts: bool=true
## If true, assign copied scripts to the nodes in cloned packedscene. 
## If copy_scripts=false, doesnt happen. 
## Alternatively, you can clone with copy_scripts=true and assign_scripts=false,
## then in Inspector manually replace each node script in cloned scene.
@export var assign_scripts: bool=true
## If true, copy exported values from original scene. 
## if copy_scripts=false or assign_scripts=false, doesnt happen.
## This is necessary otherwise assign_scripts (node.set_script) resets custom exported values to default.
## Exported values of type Script are not copied (or assign scripts would fail). 
@export var copy_exports: bool=true

##########################################################################
## MAIN SCRIPT
var _output_folder: String
var _output_folder_scripts: String# for dependencies
var _output_prefix: String# same as output_prefix
var _output_folder_packedscenes: String# for packedscenes
signal cloning(_output_folder: String)
func launch_function():
	#print("CLONING ")
	## Setup
	if not packedscene:
		return
	if not output_folder:
		_output_folder=get_output_folder(packedscene)
	else:
		_output_folder=output_folder
	cloning.emit(_output_folder)
	_output_folder_scripts=_output_folder+"/script"
	_output_prefix=output_prefix
	make_dir(_output_folder)
	if clear_output:
		empty_dir(_output_folder)
	make_dir(_output_folder_scripts)
	## Clone packedscene
	clone_packedscene(packedscene)
	packedscene=null
	## Rescan Filesystem
	_rescan_filesystem()

######################################################################
## METHODS

## Clone a packedscene
func clone_packedscene(input_packedscene: PackedScene):
	## Copy Root node Instance
	var scene: Node=input_packedscene.instantiate()## see GenEditState
	var new_scene: Node=scene.duplicate(15)# value from DuplicateFlags
	## Get all childs and subchilds
	var all_new_scene_childs: Array[Node]=get_all_children(new_scene)
	## Copy all scripts
	if copy_scripts:
		copy_node_script(new_scene)
		for i in all_new_scene_childs:
			copy_node_script(i)
		## Match exported properties for all nodes (exported properties in particular)
		if assign_scripts and copy_exports:
			match_node_exported_properties(new_scene,scene)
			for i in all_new_scene_childs:
				var i_nodepath: NodePath=i.get_owner().get_path_to(i)
				var i_original: Node=scene.get_node_or_null(i_nodepath)
				match_node_exported_properties(i,i_original)
	## SAVE
	var output_packedscene_path=get_root_output_packedscene_path(input_packedscene)
	pack_and_save_scene(new_scene,output_packedscene_path)

# Get name of output_folder: test.tscn->clone_test/
func get_output_folder(input_packedscene: PackedScene):
	var input_packedscene_path=input_packedscene.get_path()
	var input_packedscene_filename: String= input_packedscene_path.get_file()
	return "res://clone_"+input_packedscene_filename.replace(".tscn","")
	
## Manage output_folder filename for packedscene
func get_root_output_packedscene_path(input_packedscene: PackedScene):
	var input_packedscene_path=input_packedscene.get_path()
	var input_packedscene_filename: String= input_packedscene_path.get_file()
	var output_packedscene_path: String=_output_folder+"/"+_output_prefix+input_packedscene_filename
	return output_packedscene_path

## Manage output_folder filenames for scripts
func get_output_script_path(input_script: Script)->String:
	var input_res_path: String=input_script.get_path()
	var input_res_dir: String=input_res_path.get_base_dir()
	var input_res_filename: String= input_res_path.get_file()
	var output_res_dir=_output_folder_scripts+"/"+input_res_dir.replace("res://","")
	var output_res_path=output_res_dir+"/"+_output_prefix+input_res_filename
	return output_res_path

func copy_node_script(input_node: Node)->void:# copy all node resources
	## Copy/Reassign Scene Resources
	var script: Script=input_node.get_script()# A RESOURCE
	if script:
		var new_script=script.duplicate()
		var output_script_path: String=get_output_script_path(script)
		save_resource(new_script,output_script_path)
		if assign_scripts:# this erases exported values
			var reload_new_script: Script=load(output_script_path)
			input_node.set_script(reload_new_script)
			reload_new_script.reload()

## Match exported properties between node i(copy) and original
func match_node_exported_properties(node: Node, node_original: Node):
	var _properties: Array[Dictionary]=node.get_property_list()
	for j in _properties:
		# 2: is stored, 4: is shown in editor (default for exported properties)
		if j.has("usage") and flags_are_enabled(j["usage"],[2,4]):# cf PropertyUsageFlags
			if node_original and j.has("name"):
				if node.get(j["name"])!=node_original.get(j["name"]):
					if not node.get(j["name"]) is Script:# dont copy scripts!
						node.set(j["name"],node_original.get(j["name"]))

#######################################################################
## UTILS (reusable)

## Pack and save a scene
func pack_and_save_scene(scene: Node, path: String)->void:
	var ipackedscene: PackedScene=PackedScene.new()
	var error = ipackedscene.pack(scene)
	save_resource(ipackedscene,path)

## Save a Resource (make all necessary directories)
func save_resource(resource: Resource,resource_path: String):
	var resource_dir: String=resource_path.get_base_dir()
	make_dir(resource_dir)
	var error = ResourceSaver.save(resource, resource_path) 
	if error != OK:
		push_error("An error occurred while saving: "+resource_path)

## Make a directory (making all intermediary dir)
func make_dir(output_dir: String):
	var error=DirAccess.make_dir_recursive_absolute(output_dir)
	if error != OK:
		push_error("An error occurred while making folder: "+output_dir)

## Empty a directory (recursive)
func empty_dir(input_dir_path: String):
	var dir = DirAccess.open(input_dir_path)
	var step: bool
	step=remove_dir_files(input_dir_path)
	for i in dir.get_directories():
		var i_path: String=input_dir_path+"/"+i
		step=remove_dir(i_path)
	return true

## Remove a directory (recursive)
func remove_dir(input_dir_path: String):
	var step: bool=empty_dir(input_dir_path)
	DirAccess.remove_absolute(input_dir_path)
	return true
	
## Remove all files within a directory
func remove_dir_files(input_dir: String):
	var dir = DirAccess.open(input_dir)
	for file in dir.get_files():
		dir.remove(file)
	return true

func get_all_children(node: Node)->Array[Node]:## Get all childs and subchilds of a node
	var nodes : Array[Node] = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

## Check for flags in int enums from @GlobalScope
func flags_are_enabled(b: int, flags: Array[int]):
	var istrue=true
	for i in flags:
		if not flag_is_enabled(b,i):
			istrue=false
	return istrue
func flag_is_enabled(b: int, flag: int):
	return b & flag != 0
func set_flag(b: int, flag: int):
	b = b|flag
	return b
func unset_flag(b: int, flag):
	b = b & ~flag
	return b

## rescan(refresh) all files in Godot Editor
func _rescan_filesystem():
	EditorInterface.get_resource_filesystem().scan()

###############################################################################
## DRAFTS

#func copy_packedscene_no_modif(input_packedscene: PackedScene):
	#var packedscene: PackedScene=input_packedscene.duplicate(true)# true for deep
	#var output_packedscene_path=get_root_output_packedscene_path(input_packedscene)
	#save_resource(packedscene,output_packedscene_path)
	#
#func copy_packedscene_modif(input_packedscene: PackedScene):
	#var new_scene: Node=input_packedscene.instantiate().duplicate(8)# value from DuplicateFlags
	#var output_packedscene_path=get_root_output_packedscene_path(input_packedscene)
	#pack_and_save_scene(new_scene, output_packedscene_path)
#

#func copy_script(input_script: Resource):
	#make_output_dirs_of_resource(input_script)# make directories
	#var _instance=copy_resource_direxists(input_script)# copy in directory
	#return _instance

### Make all directories of resource for it to be copied
#func make_output_dirs_of_resource(input_resource: Resource):
	#if input_resource!=null:
		#var input_res_path: String=input_resource.get_path()
		#var input_res_dir: String=input_res_path.get_base_dir()
		#var output_res_dir=_output_folder+"/"+input_res_dir.replace("res://","")
		#make_dir(output_res_dir)

#func copy_resource_direxists(input_resource: Resource):
	#var input_res_path: String=input_resource.get_path()
	#var input_res_dir: String=input_res_path.get_base_dir()
	#var input_res_filename: String= input_res_path.get_file()
	#var output_res_dir=_output_folder+"/"+input_res_dir.replace("res://","")
	#var output_res_path=output_res_dir+"/"+_output_prefix+input_res_filename
	#save_resource(input_resource, output_res_path)

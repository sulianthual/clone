extends Control

## Scribbler: Scribble drawings in the editor
##

## Path of file currently edited ("" for none)
@export var edited_file: String="":
	set(value):
		edited_file=value
		if edited_file_label:
			edited_file_label.text=edited_file
## image width (pixels) (as controlled here instead of drawing)
@export var px: int=256
## image height (pixels) (as controlled here instead of drawing)
@export var py: int=256
var brush_colors: Array[Color]=[Color.DARK_RED,\
Color(0.15,0.15,0.15),\
Color(0.3,0.3,0.3),Color(0.45,0.45,0.45),\
Color(0.6,0.6,0.6),Color(0.75,0.75,0.75),\
Color(0.9,0.9,0.9)]


#############################################################
## SETUP

## menu
## drawing
@onready var drawing_container: MarginContainer = %drawing_container
@onready var drawing: TextureRect=%drawing
@onready var image_size_label: Label=%image_size
@onready var edited_file_label: Label=%edited_file
## dock
@onready var menu: Button = %menu

## file
#@onready var mode_button: Button = %mode
@onready var new: Button = %new# new drawing
@onready var load: Button = %load# load drawing
@onready var save: Button = %save# save drawing
## edit
@onready var clear: Button = %clear# clear drawing (same as new drawing)

## drawing tools
@onready var pen_button: Button=%pen
@onready var pen_overfirstbehindblack_button: Button=%pen_overfirstbehindblack
@onready var pen_black_button: Button=%pen_black
@onready var bucket_button: Button=%bucket
@onready var pen_behindblack_button: Button=%pen_behindblack# behind black
@onready var swap_dual: Button=%swap_dual
## drawing tools erase mode (just icons)
@onready var over_eraserblack = %over_eraserblack
@onready var over_eraser = %over_eraser
@onready var over_eraserbehindblack = %over_eraserbehindblack
@onready var over_eraseroverfirstbehindblack = %over_eraseroverfirstbehindblack
@onready var over_eraserbucket = %over_eraserbucket
@onready var over_buttons: Array[MarginContainer]=[over_eraserblack,over_eraser,over_eraserbehindblack,over_eraseroverfirstbehindblack,over_eraserbucket]
## colors
@onready var brush_color_1: Button = %brush_color1
@onready var brush_color_2: Button = %brush_color2
@onready var brush_color_3: Button = %brush_color3
@onready var brush_color_4: Button = %brush_color4
@onready var brush_color_5: Button = %brush_color5
@onready var brush_color_6: Button = %brush_color6
@onready var brush_color_7: Button = %brush_color7
@onready var brush_buttons: Array[Button]=[brush_color_1,brush_color_2,brush_color_3,brush_color_4,brush_color_5,brush_color_6,brush_color_7]
## text
@onready var pen_text: Button = %pen_text
@onready var text_layer: Control = %text_layer

func _ready():
	## drawer
	drawing.connect("data_dropped",_on_drawing_data_dropped)
	drawing.connect("px_changed",_on_drawing_px_changed)
	drawing.connect("py_changed",_on_drawing_py_changed)
	drawing.connect("mouse_entered",drawing.activate)
	drawing.connect("mouse_exited",drawing.deactivate)
	drawing.connect("brush_scaling_changed",on_drawing_brush_scaling_changed)
	drawing.connect("color_picked",on_drawing_color_picked)
	drawing.connect("draw_mode_changed",on_drawing_draw_mode_changed)
	drawing.connect("draw_mode_duals_updated",on_drawing_draw_mode_duals_updated)
	## utils
	## edit buttons
	clear.connect("pressed",_on_clear_pressed)
	
	## files
	new.connect("pressed",_on_new_pressed)
	save.connect("pressed",_on_save_pressed)
	load.connect("pressed",_on_load_pressed)
	## tools
	pen_black_button.connect("pressed",_on_draw_mode_pressed.bind("penblack"))
	pen_button.connect("pressed",_on_draw_mode_pressed.bind("pen"))
	pen_behindblack_button.connect("pressed",_on_draw_mode_pressed.bind("penbehindblack"))
	pen_overfirstbehindblack_button.connect("pressed",_on_draw_mode_pressed.bind("penoverfirstbehindblack"))
	bucket_button.connect("pressed",_on_draw_mode_pressed.bind("bucket"))
	swap_dual.connect("pressed",_on_swap_dual_pressed)
	## colors
	var ic: int=0
	for i in brush_buttons:
		i.connect("pressed",_on_brush_color_i_pressed.bind(ic))
		i.connect("mouse_entered",_on_brush_color_i_mouse_entered.bind(ic))
		i.connect("mouse_exited",_on_brush_color_i_mouse_exited.bind(ic))
		i.connect("data_dropped",_on_brush_color_i_data_dropped.bind(ic))
		i.connect("colors_dropped",_on_brush_color_i_colors_dropped.bind(ic))
		ic+=1
	## text
	pen_text.connect("pressed",_on_pen_text_pressed)
	## others
	_update_image_size_label()
	ready_brush_color()# wa make_brush+color
	ready_drawing_tools()
	### load icons manuall
	#pen_black_button.add_theme_icon_override()
	
	## deferred
	_postready.call_deferred()
	
func _postready()->void:
	drawing.new_drawing(px,py)
	on_drawing_brush_scaling_changed()


################################################################
## DRAWING WINDOW

func _on_drawing_px_changed(input_px: int):## SIGNAL FROM DRAWING
	px=input_px# happens e.g. when loading new file
	_update_image_size_label()
func _on_drawing_py_changed(input_py: int):## SIGNAL FROM DRAWING
	py=input_py
	_update_image_size_label()
func _update_image_size_label():
	image_size_label.text=str(px)+"x"+str(py)
	
func _on_drawing_data_dropped(_filename: String):
	if ResourceLoader.exists(_filename):
		load_selected(_filename)
################################################################
## MENU 

## MENU INPUTS
## some button (e.g. colors) can be right clicked
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if brush_color_i_hovered!=-1:
				# could have consecutive mouse events, put exclusive window unfocuses the window
				brush_color_i_pick_color()


################################################################
## EDIT
	
## CLEAR DRAWING
func _on_clear_pressed():
	drawing.clear_drawing()

## RESIZE DRAWING
func resize_drawing(input_px,input_py):
	px=int(input_px)
	py=int(input_py)
	drawing.rescale_drawing(px,py)#stretch
	#drawing.crop_drawing_centered(px,py)#crop_centered
	#drawing.crop_drawing_cornered(px,py)#crop_cornered

##
func _on_pen_text_pressed():
	text_layer.activate()
#############################################################################################3
## DRAWING TOOLS

func ready_drawing_tools():
	_update_draw_mode()
	pen_black_button.grab_focus()# must match starting draw mode

## Draw mode (must match drawing.gd)
var draw_mode: String="penblack"
var draw_mode_inverted: bool=false
func _on_draw_mode_pressed(input_tool: String):
	text_layer.deactivate()
	if input_tool=="pen":# color pen
		#if draw_mode_inverted:
		draw_mode="pen" if not draw_mode_inverted else "eraser"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="penblack":
		draw_mode="penblack" if not draw_mode_inverted else "eraserblack"
		drawing.resize_brush(pen_black_brush_scaling)
	elif input_tool=="penoverfirstbehindblack":# color pen
		draw_mode="penoverfirstbehindblack" if not draw_mode_inverted else "eraseroverfirstbehindblack"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="penbehindblack":
		draw_mode="penbehindblack" if not draw_mode_inverted else "eraserbehindblack"
		drawing.resize_brush(pen_color_brush_scaling)
	elif input_tool=="bucket":
		draw_mode="bucket" if not draw_mode_inverted else "bucketeraser"
		drawing.resize_brush(pen_color_brush_scaling)
	_update_draw_mode()
func _update_draw_mode():
	drawing.set_draw_mode(draw_mode)
func on_drawing_draw_mode_changed():# from drawing, for visuals
	pass## not used here, used by brush_indicator tho
func on_drawing_draw_mode_duals_updated(inversion: bool):# are we inverted or not, from drawing
	draw_mode_inverted=inversion
	for i in over_buttons:
		i.visible=inversion
func _on_swap_dual_pressed():# button swap duals
	drawing.draw_mode_duals_invert()
	
## BRUSH SIZE
## we track separately brush size for black pen or color pen
var pen_black_brush_scaling: float=1.0
var pen_color_brush_scaling: float=1.0
#brush_scaling_changed.emit()
func on_drawing_brush_scaling_changed():
	if draw_mode=="penblack" or draw_mode=="eraserblack":
		pen_black_brush_scaling=drawing.brush_scaling
	else:
		pen_color_brush_scaling=drawing.brush_scaling


## BRUSH COLOR
## brush color (as controlled here instead of drawing)
var last_brush_color_button_pressed_index: int=0# last button selected
var brush_color: Color=brush_colors[last_brush_color_button_pressed_index]
func ready_brush_color():# choose all the colors
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()
func update_brush_color_buttons():
	var ic: int=0
	for i in brush_buttons:
		i.modulate=brush_colors[ic]
		ic+=1
func recolor_brush_from_last_color_button():
	brush_color=brush_colors[last_brush_color_button_pressed_index]
	drawing.recolor_brush(brush_color)
func _on_brush_color_i_pressed(index: int):# left click
	last_brush_color_button_pressed_index=index
	recolor_brush_from_last_color_button()
	#brush_color=brush_colors[index]
	#drawing.recolor_brush(brush_color)

var brush_color_i_hovered: int=-1# -1 if none
func _on_brush_color_i_data_dropped(input_color: Color,index: int):# dropped a color
	brush_colors[index]=input_color
	last_brush_color_button_pressed_index=index
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()
	#brush_color=brush_colors[index]
	#drawing.recolor_brush(brush_color)	
func _on_brush_color_i_colors_dropped(input_colors: Array[Color],index: int)->void: # drop array of colors, apply to row
	for ic in range(len(brush_colors)):
		brush_colors[ic]=Color.WHITE
	var ic:int=0
	for i in input_colors:
		brush_colors[ic]=i
		ic+=1
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()
func _on_brush_color_i_mouse_entered(index: int):
	#print("entered: ",index)
	brush_color_i_hovered=index
func _on_brush_color_i_mouse_exited(index: int):
	#print("exited: ",index)
	brush_color_i_hovered=-1
func brush_color_i_pick_color():# right clicked
	if brush_color_i_hovered!=-1:
		_brush_color_i_dialogue(brush_color_i_hovered)
func _brush_color_i_dialogue(index: int):
	var file_dialogue = ConfirmationDialog.new()
	file_dialogue.set_size(Vector2(320, 180))
	file_dialogue.title="Pick Brush Color"
	#EditorInterface.popup_dialog_centered(file_dialogue)
	EditorInterface_popup_dialog_centered(file_dialogue)## REPLACE
	#Window.popup_exclusive_centered(file_dialogue)
	file_dialogue.connect("confirmed",_on_brush_color_i_dialogue_confirmed)
	var _dialog: ColorPicker=ColorPicker.new()
	_dialog.connect("color_changed",_on_brush_color_i_dialogue_color_changed.bind(index))
	_dialog.color=brush_colors[index]
	_dialog.picker_shape=ColorPicker.SHAPE_VHS_CIRCLE
	_dialog.deferred_mode=true
	_dialog.edit_alpha=true
	_dialog.can_add_swatches=false
	_dialog.color_modes_visible=false
	_dialog.hex_visible=false
	_dialog.presets_visible=false
	_dialog.sampler_visible=true
	_dialog.sliders_visible=true
	file_dialogue.add_child(_dialog)
	file_dialogue.popup()
	return file_dialogue
func _on_brush_color_i_dialogue_color_changed(input_color: Color, index: int):## SIGNAL FROM DIALOGUE
	last_brush_color_button_pressed_index=index
	brush_colors[index]=input_color
func _on_brush_color_i_dialogue_confirmed():
	recolor_brush_from_last_color_button()
	update_brush_color_buttons()
## BRUSH COLOR FROM DRAWING COLOR PICKER
func on_drawing_color_picked(input_color: Color):
	#print("color picked:",input_color)
	#if input_color!=Color.BLACK:# only change last color in row
	last_brush_color_button_pressed_index=len(brush_colors)-1
	brush_colors[-1]=input_color
	#brush_color=brush_colors[-1]
	#drawing.recolor_brush(brush_color)
	update_brush_color_buttons()
	recolor_brush_from_last_color_button()




################################################################
## FILES

## NEW DRAWING
func _on_new_pressed():
	drawing.new_drawing(px,py)
	edited_file=""

## LOAD FROM FILE
func _on_load_pressed():
	if edited_file:
		_load_dialogue().set_current_path(edited_file)# doesnt display name
	else:
		_load_dialogue()
func _load_dialogue():
	#var file_dialogue = EditorFileDialog.new()
	var file_dialogue = FileDialog.new()## REPLACE
	file_dialogue.clear_filters()
	file_dialogue.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.access = FileDialog.ACCESS_FILESYSTEM
	file_dialogue.filters = ["*.png ; PNG File"]
	file_dialogue.set_size(Vector2(640, 360))
	#file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
	#EditorInterface.popup_dialog_centered(file_dialogue)
	EditorInterface_popup_dialog_centered(file_dialogue)## REPLACE
	file_dialogue.connect("file_selected", _on_load_dialogue_file_loaded)
	file_dialogue.popup()
	return file_dialogue
func _on_load_dialogue_file_loaded(input_file: String):
	load_selected(input_file)
func load_selected(input_file: String):
	drawing.load_drawing(input_file)
	edited_file=input_file

## SAVE TO FILE
func _on_save_pressed():
	if edited_file:
		_save_dialogue().set_current_path(edited_file)
	else:
		_save_dialogue()
func _save_dialogue():
	var file_dialogue = FileDialog.new()## REPLACE from EditorFileDialog
	file_dialogue.clear_filters()
	file_dialogue.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialogue.access = FileDialog.ACCESS_FILESYSTEM
	file_dialogue.filters = ["*.png ; PNG File"]
	file_dialogue.set_size(Vector2(640, 360))
	#file_dialogue.set_display_mode(EditorFileDialog.DisplayMode.DISPLAY_LIST)
	#EditorInterface.popup_dialog_centered(file_dialogue)
	EditorInterface_popup_dialog_centered(file_dialogue)## REPLACE
	file_dialogue.connect("file_selected", _on_save_dialogue_file_selected)
	file_dialogue.popup()
	return file_dialogue
func _on_save_dialogue_file_selected(input_file: String):
	drawing.save_drawing(input_file)
	edited_file=input_file
	_rescan_filesystem()

################################################################
################################################################

## UTILS
## rescan directory after changing files
func _rescan_filesystem():
	#EditorInterface.get_resource_filesystem().scan()
	EditorInterface_get_resource_filesystem_scan()## REPLACE
## check if node holding texture is valid (non null, has texture...)
func _node_valid(input_node: Node):
	return input_node and "texture" in input_node
## check if texture is valid (non null, matching type, has resource path that is a png)
func _texture_valid(input_texture: Texture2D):
	var valid: bool=input_texture!=null
	valid=valid and (input_texture is ImageTexture or input_texture is CompressedTexture2D)
	valid=valid and input_texture.resource_path
	valid=valid and input_texture.resource_path.get_extension()=="png"
	return valid

#########################################################################
#########################################################################
## 2025 03 
## SOME SCRIBBLER ONLY WORK IN TOOLS, SO ADAPT TO IN-GAME


## REPLACE EDITORINTERFACE POPUP WHEN NOT IN TOOL
@onready var popup: Control = %Popup## all popups child of this dedicated node
func EditorInterface_popup_dialog_centered(file_dialogue):
	#get_viewport().gui_embed_subwindows=true
	# clear any previous popups
	for i in popup.get_children():
		popup.remove_child(i)
		i.queue_free()
	#file_dialogue.mode=Window.MODE_MAXIMIZED# no effect
	if "dialog_autowrap" in file_dialogue:
		file_dialogue.dialog_autowrap=true
	popup.add_child(file_dialogue)
	
	file_dialogue.popup_centered()


## REPLACE TOOL FUNCTION: here cannot do anything
func EditorInterface_get_resource_filesystem_scan():
	pass
	

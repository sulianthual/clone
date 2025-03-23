extends Node

## A test scene for cloning 

## All exports below (even modified) should clone
@export var a_string: String="foo"
@export var an_int: int=1 
@export var a_nodepath: NodePath
## Some Exceptions (wont clone but reset to default value):
@export var a_node: Node
@export var a_script: Script

## signal connections should clone
signal a_signal
func _ready() -> void:
	a_signal.emit()

## Other scene 

extends Control

## Layer for adding text

var active: bool=false
## CALL from droll_menu
func activate()->void:
	active=true
	visible=active
func deactivate()->void:
	active=false
	visible=active

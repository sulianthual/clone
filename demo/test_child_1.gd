extends Node

## Test1: another test scene


## Signal connections should clone
func _on_test_a_signal() -> void:
	print("received a signal")
	
## Groups should clone (this node belongs to two groups)

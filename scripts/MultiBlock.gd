class_name MultiBlock
extends Node

var mblock_pieces = []
var is_active = true

func _ready():
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 5.0
	timer.autostart = true
	var on_timeout = Callable(self, "on_deactivate").bind(timer)
	timer.timeout.connect(on_timeout)
	add_child(timer)

func on_deactivate(timer: Timer):
	timer.queue_free()
	for block in mblock_pieces:
		block.texture = load("res://assets/placeholder/Inactive.png")
	is_active = false
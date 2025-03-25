class_name MultiBlock
extends Node

@onready var board = get_node("/root/Main/Board") as Board

var mblock_pieces = []
var is_active = true

func _ready():
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = randi_range(15, 30)
	timer.autostart = true
	var on_timeout = Callable(self, "on_deactivate").bind(timer)
	timer.timeout.connect(on_timeout)
	add_child(timer)

func on_deactivate(timer: Timer):
	timer.queue_free()
	for block in mblock_pieces:
		block.is_active = false
		block.texture = load("res://assets/placeholder/single/Gray.png")
	is_active = false

func handle_erase():
	var valid_mblock_pieces = []
	for b in mblock_pieces:
		if is_instance_valid(b):
			valid_mblock_pieces.append(b)
	if valid_mblock_pieces.size() == 0:
		board.remove_mblock(self)
		queue_free()
	else:
		mblock_pieces = valid_mblock_pieces

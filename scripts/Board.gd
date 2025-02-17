class_name Board
extends Node2D

@onready var sprite = $Sprite2D
@onready var game = get_node("/root/Main") as Game

var top_left: Vector2
var block_size = 64
var width = 10
var height = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	var top_left_x = sprite.global_position.x - (block_size * (width / 2))
	var top_left_y = sprite.global_position.y - (block_size * (height / 2))
	top_left = Vector2(top_left_x, top_left_y)

func convert_mouse_pos_to_board_pos(mouse_pos: Vector2):
	var board_col = floor((mouse_pos.x - top_left.x) / block_size)
	var board_row = floor((mouse_pos.y - top_left.y) / block_size)
	if board_row >= 0 and board_row < height and board_col >= 0 and board_col < width:
		var board_pos = Vector2(board_row, board_col)
		return board_pos
	return Vector2(-1, -1)

func _process(delta):
	var camera = game.camera as Camera2D
	var mouse_pos = camera.get_global_mouse_position()
	convert_mouse_pos_to_board_pos(mouse_pos)

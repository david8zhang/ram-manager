class_name Board
extends Node2D

enum MultiBlockType {
	LINE,
	L,
	J,
	SQUARE,
	S,
	Z,
	T
}

@onready var sprite = $Sprite2D
@onready var game = get_node("/root/Main") as Game
@export var block_scene: PackedScene

var top_left: Vector2
var block_size = 64
var width = 10
var height = 20
var grid = []
var mblock_type_to_place = MultiBlockType.LINE

var curr_block_pieces = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var top_left_x = sprite.global_position.x - (block_size * (width / 2))
	var top_left_y = sprite.global_position.y - (block_size * (height / 2))
	top_left = Vector2(top_left_x, top_left_y)
	init_grid()

# Initialize board grid
func init_grid():
	for i in height:
		grid.append([])
		for j in width:
			grid[i].append(false)

func convert_world_pos_to_board_pos(world_pos: Vector2):
	var board_col = floor((world_pos.x - top_left.x) / block_size)
	var board_row = floor((world_pos.y - top_left.y) / block_size)
	if board_row >= 0 and board_row < height and board_col >= 0 and board_col < width:
		var board_pos = Vector2(board_row, board_col)
		return board_pos
	return Vector2(-1, -1)

func convert_board_pos_to_world_pos(board_pos: Vector2):
	var world_x = board_pos.y * block_size + top_left.x + (block_size / 2)
	var world_y = board_pos.x * block_size + top_left.y + (block_size / 2)
	return Vector2(world_x, world_y)

func _process(delta):
	var camera = game.camera as Camera2D
	var mouse_pos = camera.get_global_mouse_position()
	var board_pos = convert_world_pos_to_board_pos(mouse_pos)
	preview_place_block(mblock_type_to_place, board_pos)


func preview_place_block(mblock_type: MultiBlockType, board_pos: Vector2):
	clear_curr_block_pieces()
	if board_pos != Vector2(-1, -1):
		match mblock_type:
			MultiBlockType.LINE:
				preview_line_block(board_pos)
			MultiBlockType.L:
				pass
			MultiBlockType.J:
				pass
			MultiBlockType.SQUARE:
				pass
			MultiBlockType.S:
				pass
			MultiBlockType.Z:
				pass
			MultiBlockType.T:
				pass

func clear_curr_block_pieces():
	for piece in curr_block_pieces:
		piece.queue_free()
	curr_block_pieces = []

func preview_line_block(board_pos: Vector2):
	for i in range(0, 4):
		var block_pos = Vector2(board_pos.x + i, board_pos.y)
		var world_pos = convert_board_pos_to_world_pos(block_pos)
		var new_block = block_scene.instantiate() as Sprite2D
		add_child(new_block)
		new_block.global_position = world_pos
		curr_block_pieces.append(new_block)

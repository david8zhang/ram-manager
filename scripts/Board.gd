class_name Board
extends Node2D

enum RotationType {
	NONE, # None is the same as a full 360 turn
	QUARTER_TURN,
	HALF_TURN,
	THREE_QUARTER_TURN
}

enum MultiBlockType {
	LINE,
	L,
	J,
	SQUARE,
	S,
	T,
	Z
}

var mblock_to_color_mapping = [
	"LightBlue",
	"Orange",
	"Blue",
	"Yellow",
	"Green",
	"Purple",
	"Red"
]

@onready var sprite = $Sprite2D
@onready var game = get_node("/root/Main") as Game
@export var block_scene: PackedScene
@export var mblock_scene: PackedScene
@export var num_locked_cols = 2
@export var num_locked_rows = 5

# For checking bounds of board
var top_left: Vector2
var bottom_right: Vector2

var block_size = 64
var width = 10
var height = 20
var grid = []
var mblock_type_to_place = MultiBlockType.LINE
var curr_rotation_type  = RotationType.NONE
var curr_mblock_color = mblock_to_color_mapping[mblock_type_to_place as int]
var curr_mblock_pieces = []
var curr_mblocks_on_board = []
var locked_row_col_blocks = []

signal block_placed
signal block_erased

# Called when the node enters the scene tree for the first time.
func _ready():
	var top_left_x = sprite.global_position.x - (block_size * (width / 2))
	var top_left_y = sprite.global_position.y - (block_size * (height / 2))
	var bottom_right_x = sprite.global_position.x + (block_size * (width / 2))
	var bottom_right_y = sprite.global_position.y + (block_size * (height / 2))
	top_left = Vector2(top_left_x, top_left_y)
	bottom_right = Vector2(bottom_right_x, bottom_right_y)
	init_locked_rows()

func init_locked_rows():
	for i in range(0, height):
		for j in range(0, width):
			if not ((i >= num_locked_rows and i < height - num_locked_rows) and (j >= num_locked_cols and j < width - num_locked_cols)):
				locked_row_col_blocks.append(spawn_block(Vector2(i, j), "DarkGray"))

func set_new_locked_cols_and_rows(new_locked_cols: int, new_locked_rows: int):
	num_locked_rows = new_locked_cols
	num_locked_cols = new_locked_rows
	for b in locked_row_col_blocks:
		b.queue_free()
	locked_row_col_blocks = []
	init_locked_rows()


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

func _process(_delta):
	var camera = game.camera as Camera2D
	var mouse_pos = camera.get_global_mouse_position()
	var board_pos = convert_world_pos_to_board_pos(mouse_pos)
	if game.is_erase_mode:
		preview_eraser_shape(board_pos)
	else:
		preview_place_block(mblock_type_to_place, board_pos)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if game.is_erase_mode:
			erase_block()
		else:
			place_block()

func place_block():
	if !is_overlapping_with_other_mblock(curr_mblock_pieces) and is_mouse_pos_in_bounds():
		var new_mblock = mblock_scene.instantiate() as MultiBlock
		new_mblock.mblock_pieces = curr_mblock_pieces
		curr_mblocks_on_board.append(new_mblock)
		add_child(new_mblock)
		for block in curr_mblock_pieces:
			block.reparent(new_mblock)
		curr_mblock_pieces = []
		mblock_type_to_place = game.piece_menu.next_piece_type
		game.piece_menu.pick_next_random_piece()
		curr_mblock_color = mblock_to_color_mapping[mblock_type_to_place as int]
		block_placed.emit()

func is_mouse_pos_in_bounds():
	var camera = game.camera as Camera2D
	var mouse_pos = camera.get_global_mouse_position()
	return mouse_pos.x >= top_left.x and mouse_pos.y >= top_left.y and mouse_pos.x <= bottom_right.x and mouse_pos.y <= bottom_right.y

func erase_block():
	var camera = game.camera as Camera2D
	var mouse_pos = camera.get_global_mouse_position()
	var board_pos = convert_world_pos_to_board_pos(mouse_pos)
	match game.selected_eraser_shape:
		EraseButton.EraseShape.OneByOne:
			erase_one_by_one(board_pos)
		EraseButton.EraseShape.TwoByTwo:
			erase_two_by_two(board_pos)
		EraseButton.EraseShape.TwoByFour:
			erase_two_by_four(board_pos)

func erase_one_by_one(board_pos: Vector2):
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 1 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 1 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	var did_erase = false
	for m in curr_mblocks_on_board:
		for b in m.mblock_pieces:
			if is_instance_valid(b) and b.board_pos == clamped_board_pos and !b.is_active:
				b.erase()
				did_erase = true
	if did_erase:
		block_erased.emit()

func erase_two_by_two(board_pos):
	var did_erase = false
	var block_map = generate_block_map()
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 2 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	var block_positions = [
		[0, 0],
		[1, 0],
		[0, 1],
		[1, 1]
	]
	for pos in block_positions:
		var block_pos = Vector2(clamped_board_pos[0] + pos[0], clamped_board_pos[1] + pos[1])
		var block = block_map[block_pos[0]][block_pos[1]]
		if block != null and !block.is_active:
			did_erase = true
			block.erase()
			var mblock = block.get_parent() as MultiBlock
			mblock.handle_erase()
	if did_erase:
		block_erased.emit()

func erase_two_by_four(board_pos):
	var did_erase = false
	var block_map = generate_block_map()
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 4 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	var block_positions = [
		[0, 0],
		[0, 1],
		[0, 2],
		[0, 3],
		[1, 0],
		[1, 1],
		[1, 2],
		[1, 3]
	]
	for pos in block_positions:
		var block_pos = Vector2(clamped_board_pos[0] + pos[0], clamped_board_pos[1] + pos[1])
		var block = block_map[block_pos[0]][block_pos[1]]
		if block != null and !block.is_active:
			did_erase = true
			block.erase()
			var mblock = block.get_parent() as MultiBlock
			mblock.handle_erase()
	if did_erase:
		block_erased.emit()

func remove_mblock(mblock: MultiBlock):
	curr_mblocks_on_board = curr_mblocks_on_board.filter(func (m): return m != mblock)

func preview_eraser_shape(board_pos: Vector2):
	clear_eraser_preview()
	match game.selected_eraser_shape:
		EraseButton.EraseShape.OneByOne:
			preview_erase_one_by_one(board_pos)
		EraseButton.EraseShape.TwoByTwo:
			preview_erase_two_by_two(board_pos)
		EraseButton.EraseShape.TwoByFour:
			preview_erase_two_by_four(board_pos)

func preview_erase_one_by_one(board_pos):
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 1 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 1 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	for m in curr_mblocks_on_board:
		for b in m.mblock_pieces:
			if is_instance_valid(b) and b.board_pos == clamped_board_pos:
				b.modulate = Color.BLACK

func preview_erase_two_by_two(board_pos):
	var block_map = generate_block_map()
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 2 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	var block_positions = [
		[0, 0],
		[1, 0],
		[0, 1],
		[1, 1]
	]
	for pos in block_positions:
		var block_pos = Vector2(clamped_board_pos[0] + pos[0], clamped_board_pos[1] + pos[1])
		var block = block_map[block_pos[0]][block_pos[1]]
		if block != null and !block.is_active:
			block.modulate = Color.BLACK

func preview_erase_two_by_four(board_pos):
	var block_map = generate_block_map()
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 4 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	var block_positions = [
		[0, 0],
		[0, 1],
		[0, 2],
		[0, 3],
		[1, 0],
		[1, 1],
		[1, 2],
		[1, 3]
	]
	for pos in block_positions:
		var block_pos = Vector2(clamped_board_pos[0] + pos[0], clamped_board_pos[1] + pos[1])
		var block = block_map[block_pos[0]][block_pos[1]]
		if block != null and !block.is_active:
			block.modulate = Color.BLACK

func generate_block_map():
	# Construct a 2D array to represent all blocks on board
	var block_map = []
	for i in height:
		block_map.append([])
		for j in width:
			block_map[i].append(null)
	for m in curr_mblocks_on_board:
		for b in m.mblock_pieces:
			if is_instance_valid(b):
				block_map[b.board_pos.x][b.board_pos.y] = b
	return block_map

func clear_eraser_preview():
	for m in curr_mblocks_on_board:
		for b in m.mblock_pieces:
			if is_instance_valid(b):
				b.modulate = Color(1, 1, 1, 1)

func preview_place_block(mblock_type: MultiBlockType, board_pos: Vector2):
	clear_curr_block_pieces()
	if board_pos != Vector2(-1, -1):
		match mblock_type:
			MultiBlockType.LINE:
				preview_line_block(board_pos)
			MultiBlockType.L:
				preview_L_block(board_pos)
			MultiBlockType.J:
				preview_J_block(board_pos)
			MultiBlockType.SQUARE:
				preview_square_block(board_pos)
			MultiBlockType.S:
				preview_S_block(board_pos)
			MultiBlockType.Z:
				preview_Z_block(board_pos)
			MultiBlockType.T:
				preview_T_block(board_pos)

func clear_curr_block_pieces():
	for piece in curr_mblock_pieces:
		piece.queue_free()
	curr_mblock_pieces = []

func is_overlapping_with_other_mblock(curr_pieces):
	for mblock in curr_mblocks_on_board:
		for block in curr_pieces:
			if does_block_overlap(mblock, block):
				return true
	return false

func does_block_overlap(mblock: MultiBlock, block):
	for b in mblock.mblock_pieces:
		if is_instance_valid(b) and is_instance_valid(block) and b.board_pos == block.board_pos:
			return true
	return false

func spawn_block(block_pos: Vector2, color) -> Sprite2D:
	var world_pos = convert_board_pos_to_world_pos(block_pos)
	var new_block = block_scene.instantiate() as Block
	new_block.board_pos = block_pos
	new_block.curr_color = color
	add_child(new_block)
	new_block.global_position = world_pos
	return new_block

func spawn_multi_block(board_pos: Vector2, block_positions):
	for pos in block_positions:
		var block_pos = Vector2(board_pos.x + pos[0], board_pos.y + pos[1])
		var new_block = spawn_block(block_pos, curr_mblock_color)
		curr_mblock_pieces.append(new_block)

func preview_line_block(board_pos: Vector2):
	var clamped_board_pos = Vector2.ZERO
	var block_positions = []
	match curr_rotation_type:
		RotationType.QUARTER_TURN, RotationType.THREE_QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, num_locked_rows, height - 1 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 2 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, -2],
				[0, -1],
				[0, 0],
				[0, 1]
			]
		RotationType.HALF_TURN, RotationType.NONE:
			var clamped_row = clamp(board_pos.x, 2 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, num_locked_cols, width - 1 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[-2, 0],
				[-1, 0],
				[0, 0],
				[1, 0]
			]
	if clamped_board_pos != Vector2.ZERO:
		spawn_multi_block(clamped_board_pos, block_positions)

# L Block:
# *
# * * *
func preview_L_block(board_pos: Vector2):
	var clamped_board_pos = Vector2.ZERO
	var block_positions = []
	match curr_rotation_type:
		# * *
		# *
		# *
		RotationType.QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[-1, 0],
				[0, 0],
				[-1, 1],
				[1, 0]
			]
		# * * *
		#     *
		RotationType.HALF_TURN:
			var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[0, 1],
				[1, 1]
			]
		#   *
		#   *
		# * *
		RotationType.THREE_QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 1 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[-1, 0],
				[1, 0],
				[1, -1]
			]
		RotationType.NONE:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 1 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[0, 1],
				[-1, -1]
			]
	if clamped_board_pos != Vector2.ZERO:
		spawn_multi_block(clamped_board_pos, block_positions)

# J Block:
#     *
# * * *
func preview_J_block(board_pos: Vector2):
	var clamped_board_pos = Vector2.ZERO
	var block_positions = []
	match curr_rotation_type:
		# * 
		# *
		# * *
		RotationType.QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[-1, 0],
				[1, 0],
				[1, 1]
			]
		# * * *
		# *
		RotationType.HALF_TURN:
			var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[0, 1],
				[1, -1]
			]
		# * *
		#   *
		#   *
		RotationType.THREE_QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 1 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[-1, 0],
				[-1, -1],
				[1, 0]
			]
		RotationType.NONE:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 1 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[0, 1],
				[-1, 1]
			]
	if clamped_board_pos != Vector2.ZERO:
		spawn_multi_block(clamped_board_pos, block_positions)

func preview_square_block(board_pos: Vector2):
	var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
	var clamped_col = clamp(board_pos.y, num_locked_cols, width - 2 - num_locked_cols)
	var clamped_board_pos = Vector2(clamped_row, clamped_col)
	var block_positions = [
		[0, 0],
		[1, 0],
		[0, 1],
		[1, 1]
	]
	spawn_multi_block(clamped_board_pos, block_positions)

# S Block:
#   * *
# * * 
func preview_S_block(board_pos: Vector2):
	var clamped_board_pos = Vector2.ZERO
	var block_positions = []
	match curr_rotation_type:
		# *
		# * *
		#   *
		RotationType.THREE_QUARTER_TURN, RotationType.QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 1 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[-1, -1],
				[1, 0]
			]
		#   * *
		# * *
		RotationType.HALF_TURN, RotationType.NONE:
			var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[1, 0],
				[1, -1],
				[0, 1]
			]
	if clamped_board_pos != Vector2.ZERO:
		spawn_multi_block(clamped_board_pos, block_positions)

# Z Block:
# * *
#   * *
func preview_Z_block(board_pos: Vector2):
	var clamped_board_pos = Vector2.ZERO
	var block_positions = []
	match curr_rotation_type:
		#   *
		# * *
		# *
		RotationType.QUARTER_TURN, RotationType.THREE_QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 1 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[-1, 0],
				[1, -1]
			]
		RotationType.HALF_TURN, RotationType.NONE:
			var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[1, 0],
				[1, 1]
			]
	if clamped_board_pos != Vector2.ZERO:
		spawn_multi_block(clamped_board_pos, block_positions)

# (upside down) T Block:
#   *
# * * *
func preview_T_block(board_pos: Vector2):
	var clamped_board_pos = Vector2.ZERO
	var block_positions = []
	match curr_rotation_type:
		# *
		# * *
		# *
		RotationType.QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[1, 0],
				[-1, 0],
				[0, 1]
			]
		# * * *
		#   *
		RotationType.HALF_TURN:
			var clamped_row = clamp(board_pos.x, num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[0, 1],
				[1, 0]
			]
		#   *
		# * *
		#   *
		RotationType.THREE_QUARTER_TURN:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 2 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 1 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[0, -1],
				[-1, 0],
				[1, 0]
			]
		RotationType.NONE:
			var clamped_row = clamp(board_pos.x, 1 + num_locked_rows, height - 1 - num_locked_rows)
			var clamped_col = clamp(board_pos.y, 1 + num_locked_cols, width - 2 - num_locked_cols)
			clamped_board_pos = Vector2(clamped_row, clamped_col)
			block_positions = [
				[0, 0],
				[-1, 0],
				[0, 1],
				[0, -1]
			]
	if clamped_board_pos != Vector2.ZERO:
		spawn_multi_block(clamped_board_pos, block_positions)

func rotate_curr_mblock():
	curr_rotation_type = (curr_rotation_type + 1) % 4 as RotationType

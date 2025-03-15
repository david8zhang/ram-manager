class_name Game
extends Node2D

@onready var board = $Board as Board
@onready var camera = $Camera2D as Camera2D
@onready var eraser_menu = $EraserMenu as Control
@onready var erase_one_by_one = $EraserMenu/Erase1x1 as EraseButton
@onready var erase_two_by_two = $EraserMenu/Erase2x2 as EraseButton
@onready var erase_two_by_four = $EraserMenu/Erase2x4 as EraseButton
@onready var score_label = $ScoreLabel as Label
@onready var piece_menu = $PieceMenu as PieceMenu
@onready var lives_menu = $LivesMenu as LivesMenu

var selected_eraser_shape: EraseButton.EraseShape
var is_erase_mode = false
var curr_score = 0
var level = 0

const BLOCK_PLACE_SCORE = 100
const LEVEL_ONE_THRESHOLD = 1500
const LEVEL_TWO_THRESHOLD = 3000
const LEVEL_THREE_THRESHOLD = 10000

# Called when the node enters the scene tree for the first time.
func _ready():
	# Wire up erase button selection
	var children = eraser_menu.get_children()
	for child in children:
		if child is EraseButton:
			var erase_button = child as EraseButton
			erase_button.select_eraser.connect(on_eraser_selected)
	piece_menu.timer_expired.connect(handle_life_decrease)
	board.block_placed.connect(updated_score)
	board.block_erased.connect(block_erased)

func on_eraser_selected(eraser_shape):
	board.clear_curr_block_pieces()
	selected_eraser_shape = eraser_shape
	is_erase_mode = true

func updated_score():
	curr_score += BLOCK_PLACE_SCORE
	score_label.text = "Score: " + str(curr_score)
	if level < 1 and curr_score >= LEVEL_ONE_THRESHOLD:
		level = 1
		board.set_new_locked_cols_and_rows(3, 2)
		piece_menu.set_new_expiry_timer(15)
	if level < 2 and curr_score >= LEVEL_TWO_THRESHOLD:
		level = 2
		board.set_new_locked_cols_and_rows(2, 1)
		piece_menu.set_new_expiry_timer(10)
	if level < 3 and curr_score >= LEVEL_THREE_THRESHOLD:
		level = 3
		board.set_new_locked_cols_and_rows(0, 0)
		piece_menu.set_new_expiry_timer(5)

func _process(_delta):
	if Input.is_action_just_pressed("disable_erase"):
		board.clear_eraser_preview()
		is_erase_mode = false
	if Input.is_action_just_pressed("rotate"):
		board.rotate_curr_mblock()
	if Input.is_action_just_pressed("1x1_eraser_hotkey"):
		if !erase_one_by_one.is_on_cooldown:
			on_eraser_selected(EraseButton.EraseShape.OneByOne)
	if Input.is_action_just_pressed("2x2_eraser_hotkey"):
		if !erase_two_by_two.is_on_cooldown:
			on_eraser_selected(EraseButton.EraseShape.TwoByTwo)
	if Input.is_action_just_pressed("2x4_eraser_hotkey"):
		if !erase_two_by_four.is_on_cooldown:
			on_eraser_selected(EraseButton.EraseShape.TwoByFour)

func handle_life_decrease():
	lives_menu.decrease_lives()

func block_erased():
	match selected_eraser_shape:
		EraseButton.EraseShape.OneByOne:
			erase_one_by_one.begin_cooldown()
		EraseButton.EraseShape.TwoByTwo:
			erase_two_by_two.begin_cooldown()
		EraseButton.EraseShape.TwoByFour:
			erase_two_by_four.begin_cooldown()
	board.clear_eraser_preview()
	is_erase_mode = false

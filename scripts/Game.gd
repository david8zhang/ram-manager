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
@onready var alert_panel = $AlertPanel as Panel
@onready var animation_player = $AnimationPlayer as AnimationPlayer

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

	var callable = Callable(self, "handle_piece_timer_tick")
	piece_menu.on_timer_tick.connect(callable)
	board.block_placed.connect(updated_score)
	board.block_placed.connect(stop_flashing_alert_panel)
	board.block_erased.connect(block_erased)

func on_eraser_selected(eraser_shape):
	board.clear_curr_block_pieces()
	selected_eraser_shape = eraser_shape
	is_erase_mode = true

func handle_piece_timer_tick(seconds_remaining: int):
	# Show alert flash if timer running out
	match level:
		0:
			if seconds_remaining <= 10:
				flash_alert_panel()
		1:
			if seconds_remaining <= 7:
				flash_alert_panel()
		2:
			if seconds_remaining <= 5:
				flash_alert_panel()
		3:
			if seconds_remaining <= 3:
				flash_alert_panel()

func flash_alert_panel():
	animation_player.play("flash_alert")

func stop_flashing_alert_panel():
	animation_player.stop()
	alert_panel.modulate.a = 0

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
		piece_menu.set_new_expiry_timer(6)

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
	if lives_menu.remaining_lives == 0:
		PlayerVariables.player_score = curr_score
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

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

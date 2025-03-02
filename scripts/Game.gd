class_name Game
extends Node2D

@onready var board = $Board as Board
@onready var camera = $Camera2D as Camera2D

var selected_eraser_shape: EraseButton.EraseShape
var is_erase_mode = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Wire up erase button selection
	var children = get_children()
	for child in children:
		if child is EraseButton:
			var erase_button = child as EraseButton
			erase_button.select_eraser.connect(on_eraser_selected)

func on_eraser_selected(eraser_shape):
	selected_eraser_shape = eraser_shape
	is_erase_mode = true

func _process(_delta):
	if Input.is_action_just_pressed("disable_erase"):
		is_erase_mode = false
	if Input.is_action_just_pressed("rotate"):
		board.rotate_curr_mblock()

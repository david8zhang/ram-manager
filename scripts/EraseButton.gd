class_name EraseButton
extends Node2D

enum EraseShape {
	OneByOne,
	TwoByTwo,
	TwoByFour
}

@export var eraser_shape = EraseShape.OneByOne
@onready var button = $Button as Button
@onready var panel = $Panel as Panel
var is_on_cooldown = false

signal select_eraser(shape: EraseShape)

# Called when the node enters the scene tree for the first time.
func _ready():
	var on_button_pressed = Callable(self, "eraser_selected")
	button.pressed.connect(on_button_pressed)

func eraser_selected():
	select_eraser.emit(eraser_shape)

func begin_cooldown():
	is_on_cooldown = true
	panel.show()
	var timer = Timer.new()
	timer.wait_time = get_cooldown_for_erase_shape()
	timer.autostart = true
	timer.one_shot = true
	timer.timeout.connect(end_cooldown)
	add_child(timer)

func end_cooldown():
	is_on_cooldown = false
	panel.hide()

func get_cooldown_for_erase_shape():
	match eraser_shape:
		EraseShape.OneByOne:
			return 1.5
		EraseShape.TwoByTwo:
			return 3.0
		EraseShape.TwoByFour:
			return 5.0
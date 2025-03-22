class_name Start
extends Node2D

@onready var start_button = $CanvasLayer/Control/Button as Button

# Called when the node enters the scene tree for the first time.
func _ready():
	start_button.pressed.connect(go_to_next_scene)

func go_to_next_scene():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
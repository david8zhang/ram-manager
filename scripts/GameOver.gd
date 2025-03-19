class_name GameOver
extends Node2D

@onready var score = $CanvasLayer/Score as Label
@onready var play_again_button = $CanvasLayer/PlayAgain as Button

func _ready():
	score.text = "Score: " + str(PlayerVariables.player_score)
	play_again_button.pressed.connect(restart_game)

func restart_game():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

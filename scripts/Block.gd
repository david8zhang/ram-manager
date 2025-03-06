class_name Block
extends Sprite2D

var curr_color = "Blue"
var board_pos = Vector2.ZERO
var is_active = true

# Called when the node enters the scene tree for the first time.
func _ready():
	texture = load("res://assets/placeholder/single/" + curr_color + ".png")

func erase():
	queue_free()
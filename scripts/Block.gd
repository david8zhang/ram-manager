class_name Block
extends Node2D

enum BlockType {
	LINE,
	L,
	J,
	SQUARE,
	S,
	Z,
	T
}

var block_width
var block_height

@onready var sprite = $Sprite2D as Sprite2D

func _ready():
	sprite.visible = false

func create(block_type: BlockType):
	match block_type:
		BlockType.LINE:
			sprite.texture = load("res://assets/placeholder/multi/I.png")
		BlockType.L:
			sprite.texture = load("res://assets/placeholder/multi/L.png")
	sprite.visible = true
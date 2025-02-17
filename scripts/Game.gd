class_name Game
extends Node2D

@onready var board = $Board as Board
@onready var camera = $Camera2D as Camera2D
@export var block_scene: PackedScene

var block_to_place: Block

# Called when the node enters the scene tree for the first time.
func _ready():
	block_to_place = block_scene.instantiate() as Block
	add_child(block_to_place)
	block_to_place.create(Block.BlockType.LINE)


func _process(delta):
	var mouse_position = camera.get_global_mouse_position()
	block_to_place.global_position = mouse_position

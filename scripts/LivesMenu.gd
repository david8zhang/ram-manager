class_name LivesMenu
extends PanelContainer

@onready var lives_label = $VBoxContainer/LivesLabel as Label
var remaining_lives = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	lives_label.text = str(remaining_lives)

func decrease_lives():
	remaining_lives -= 1
	lives_label.text = str(remaining_lives)
	var lives_lost_label = Label.new()
	lives_lost_label.text = "Lost 1 life!"
	lives_lost_label.add_theme_font_size_override("font_size", 35)
	lives_lost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(lives_lost_label)
	var initial_pos = Vector2(lives_label.global_position.x, lives_label.global_position.y)
	lives_lost_label.global_position = Vector2(initial_pos.x, initial_pos.y)
	var tween = create_tween()
	tween.tween_property(lives_lost_label, "global_position:y", initial_pos.y - 50, 1.5)
	tween.parallel().tween_property(lives_lost_label, "modulate:a", 0, 1.5)

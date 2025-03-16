class_name PieceMenu
extends PanelContainer

@onready var next_piece_type
@onready var next_piece_preview = $VBoxContainer/TextureRect as TextureRect
@onready var countdown_timer_label = $VBoxContainer/PieceMenuCountdown as Label
var initial_countdown_seconds = 20
var countdown_seconds = initial_countdown_seconds
var countdown_timer: Timer

signal timer_expired
signal on_timer_tick(seconds_remaining)

# Called when the node enters the scene tree for the first time.
func _ready():
	pick_next_random_piece()
	countdown_timer_label.text = str(countdown_seconds)
	setup_countdown_timer()

func setup_countdown_timer():
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	countdown_timer.autostart = true
	var on_timeout = Callable(self, "timer_tick")
	countdown_timer.timeout.connect(on_timeout)
	add_child(countdown_timer)

func timer_tick():
	if countdown_seconds == 0:
		countdown_timer.stop()
		timer_expired.emit()

		# Add slight delay
		var timer = Timer.new()
		timer.wait_time = 1.5
		timer.autostart = true
		timer.one_shot = true
		var on_timeout = Callable(self, "restart_timer")
		timer.timeout.connect(on_timeout)
		add_child(timer)
	else:
		countdown_seconds -= 1
		on_timer_tick.emit(countdown_seconds)
		countdown_timer_label.text = str(countdown_seconds)

func restart_timer():
	countdown_seconds = initial_countdown_seconds
	countdown_timer_label.text = str(countdown_seconds)
	countdown_timer.start()

func set_new_expiry_timer(new_countdown_seconds):
	initial_countdown_seconds = new_countdown_seconds
	restart_timer()

func pick_next_random_piece():
	if countdown_timer != null:
		restart_timer()
	next_piece_type = Board.MultiBlockType.values().pick_random()
	var texture_name = ""
	match next_piece_type:
		Board.MultiBlockType.LINE:
			texture_name = "I"
		Board.MultiBlockType.L:
			texture_name = "L"
		Board.MultiBlockType.J:
			texture_name = "J"
		Board.MultiBlockType.SQUARE:
			texture_name = "O"
		Board.MultiBlockType.S:
			texture_name = "S"
		Board.MultiBlockType.Z:
			texture_name = "Z"
		Board.MultiBlockType.T:
			texture_name = "T"
	next_piece_preview.texture = load("res://assets/placeholder/multi/" + texture_name + ".png")
		

extends TextureProgressBar

@export var player: Player

const COLOR_HIGH := Color("#3b6e4c")   # greenish
const COLOR_MEDIUM := Color("#7c5c3c") # brownish
const COLOR_CRITICAL := Color("#8c1a1a") # red


func _ready():
	player.healthChanged.connect(update)
	update()


func update():
	if player.maxHealth == 0:
		value = 0
		return
		
	value = player.currentHealth * 100 / player.maxHealth
	update_color()

func update_color() -> void:
	var health_ratio = float(player.currentHealth) / float(player.maxHealth)
	
	if health_ratio > 0.6:
		tint_progress = COLOR_HIGH
	elif health_ratio > 0.3:
		tint_progress = COLOR_MEDIUM
	else:
		tint_progress = COLOR_CRITICAL

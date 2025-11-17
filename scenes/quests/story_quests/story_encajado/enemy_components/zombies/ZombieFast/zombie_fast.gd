extends ZombieBase
class_name ZombieFast

func _ready():
	move_speed = 250.0
	max_health = 30
	uses_run_animation = true
	super._ready()
	print("🏃 Runner zombie ready")

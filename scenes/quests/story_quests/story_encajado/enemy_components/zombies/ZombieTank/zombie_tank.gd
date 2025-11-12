extends ZombieBase
class_name ZombieTank

func _ready():
	move_speed = 60.0
	max_health = 200
	has_attack_animation = true
	super._ready()
	print("💪 Tank zombie ready")

extends ZombieBase
class_name ZombieSpitter

@export var spit_scene: PackedScene
@export var spit_cooldown: float = 2.5
var can_spit = true

func _ready():
	move_speed = 100.0
	max_health = 70
	has_attack_animation = true
	super._ready()
	print("🧟‍♀️ Spitter zombie ready")

func _physics_process(delta):
	super._physics_process(delta)
	
	# Only spit when not dead and within attack range
	if player and can_spit and not dead:
		var dist = global_position.distance_to(player.global_position)
		if dist < 350:
			await attack()  # Wait to not overlap spitting cycles

func attack() -> void:
	if not can_spit or dead:
		return

	can_spit = false
	attacking = true

	_play_animation("attack")
	await sprite.animation_finished

	# Fire spit projectile
	if spit_scene and player:
		var spit = spit_scene.instantiate()
		spit.global_position = global_position
		spit.direction = (player.global_position - global_position).normalized()
		get_parent().add_child(spit)
		print("💦 Spitter fired projectile!")

	attacking = false
	await get_tree().create_timer(spit_cooldown).timeout
	can_spit = true

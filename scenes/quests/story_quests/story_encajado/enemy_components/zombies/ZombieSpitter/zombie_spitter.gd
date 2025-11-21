extends ZombieBase
class_name ZombieSpitter

@export var Bullet: PackedScene
# REMOVED: @export var enemy: CharacterBody2D -> You don't need this, the script IS on the enemy.

@onready var BulletManager = $BulletManager
@onready var ShootSpeed = $ShootTimer

func _ready():
	override_attack_logic = true
	move_speed = 100
	max_health = 30
	uses_run_animation = false
	# Ensure we get the player reference using the Base logic
	super._ready() 
	print("🏃 Spitter zombie ready")

func _physics_process(delta: float) -> void:
	# 1. Safety Checks (inherited from Base)
	if dead or is_hurt:
		move_and_slide() # Let gravity/knockback work
		return

	if not player:
		return

	# 2. Calculate Distance
	var distance = global_position.distance_to(player.global_position)
	var direction_vector = (player.global_position - global_position).normalized()

	# 3. Movement & Attack Logic
	if distance < 300:
		# STOP moving to shoot
		velocity = Vector2.ZERO
		
		if ShootSpeed.is_stopped():
			shoot()
			ShootSpeed.wait_time = 0.5
			ShootSpeed.start()
	else:
		# MOVE towards player
		velocity = direction_vector * move_speed

	# 4. Apply Movement
	move_and_slide()

	# 5. ANIMATION FIX (This was missing!) 
	# We use the helper function from ZombieBase
	
	# Handle Sprite Flipping
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	# Handle Animation State
	if velocity.length() > 0:
		_play_animation("walk")
	else:
		# If we are standing still (shooting), play idle
		# Note: If you have a "shoot" animation, put it here!
		_play_animation("idle")

func shoot() -> void:
	print("the enemy shot!")
	if Bullet:
		var bullet_instance = Bullet.instantiate()
		get_tree().current_scene.add_child(bullet_instance)
		
		# Use global_position of the marker, or self if marker is missing
		if BulletManager:
			bullet_instance.global_position = BulletManager.global_position
		else:
			bullet_instance.global_position = global_position

		var target = player.global_position
		var direction_to_player = (target - bullet_instance.global_position).normalized()

		if bullet_instance.has_method("set_direction"):
			bullet_instance.set_direction(direction_to_player)
			bullet_instance.speed = 5

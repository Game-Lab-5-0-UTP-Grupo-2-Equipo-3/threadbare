extends ZombieBase
class_name ZombieSpitter

@export var Bullet: PackedScene
@export var enemy: CharacterBody2D

@onready var BulletManager = $BulletManager
@onready var ShootSpeed = $ShootTimer


func _ready():
	override_attack_logic = true
	move_speed = 100
	max_health = 30
	uses_run_animation = false
	player = get_tree().get_first_node_in_group("Player")
	super._ready()
	print("🏃 Spitter zombie ready")

func shoot() -> void:
	print("the enemy shot!")
	var bullet_instance = Bullet.instantiate()
	get_tree().current_scene.add_child(bullet_instance)

	bullet_instance.global_position = BulletManager.global_position

	var target = player.global_position
	var direction_to_player = (target - bullet_instance.global_position).normalized()

	bullet_instance.set_direction(direction_to_player)
	bullet_instance.speed = 5

func _physics_process(delta: float) -> void:
	var direction = player.global_position - enemy.global_position

	if direction.length() < 300:
		if ShootSpeed.is_stopped():
			shoot()
			ShootSpeed.wait_time = 0.5
			ShootSpeed.start()

	if direction.length() > 300:
		enemy.velocity = direction.normalized() * move_speed

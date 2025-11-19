extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 120.0
@export var damage: int = 10
@export var knockback_power: float = 300.0
@export var detection_radius: float = 1000
@export var max_health: int = 50
@export var has_attack_animation: bool = false
@export var uses_run_animation: bool = false
@export var hurt_lock_time: float = 0.4  # Pause after being hit

var current_health: int
var player: CharacterBody2D

var attacking: bool = false
var dead: bool = false
var is_hurt: bool = false
var is_spitting: bool = false   # For ranged attackers

# 🆕 If TRUE, child scripts override melee attack logic (ZombieSpitter uses this)
var override_attack_logic: bool = false

signal enemy_died

@onready var attack_area: Area2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_timer: Timer = Timer.new()


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	current_health = max_health
	add_child(hurt_timer)
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)

	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if hurt_box:
		hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	else:
		print("⚠️ No HurtBox found")

	print("🧟 Zombie spawned with health:", current_health)


func _physics_process(delta: float) -> void:
	if dead or is_hurt:
		move_and_slide()
		return

	# Find player if not cached yet
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	var distance = global_position.distance_to(player.global_position)

	# 🧟‍♂️ Default melee attack lock (disabled if child overrides)
	if attacking and not override_attack_logic:
		_play_animation("attack")
		move_and_slide()
		return

	# Move if close enough
	if distance <= detection_radius:
		_move_toward_player()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Flip sprite based on direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	if override_attack_logic:
	# Child monster like the Spitter can define its own attack flag
		if ("is_spitting" in self) and self.is_spitting:
			return
	# Or if child manages "attacking"
		if attacking:
			return


	# Animation logic
	if velocity.length() < 10:
		_play_animation("idle")
	else:
		if uses_run_animation and move_speed > 150:
			_play_animation("run")
		else:
			_play_animation("walk")


# --- MOVEMENT ---
func _move_toward_player() -> void:
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed


# --- MELEE ATTACK HANDLING ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if dead or is_hurt:
		return

	if body.is_in_group("player"):
		print("💥 player hit:", body.name)

		if has_attack_animation:
			await attack()

		body.hurtByEnemy(self)


func attack() -> void:
	if attacking or dead or is_hurt:
		return

	attacking = true
	_play_animation("attack")

	await sprite.animation_finished

	attacking = false


# --- DAMAGE HANDLING ---
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if dead:
		return

	if area.is_in_group("PlayerProjectile") or area.is_in_group("bullet"):
		var dmg = 40
		if area.has_method("get_damage"):
			dmg = area.get_damage()

		take_damage(dmg)

		if area.has_method("queue_free"):
			area.queue_free()


func take_damage(amount: int) -> void:
	if dead:
		return

	current_health -= amount
	is_hurt = true
	velocity = Vector2.ZERO

	_play_animation("hurt")
	hurt_timer.start(hurt_lock_time)

	if current_health <= 0:
		die()


func _on_hurt_timer_timeout() -> void:
	is_hurt = false


# --- DEATH ---
func die() -> void:
	if dead:
		return

	dead = true
	_play_animation("death")
	emit_signal("enemy_died")

	await sprite.animation_finished
	queue_free()


# --- ANIMATION HELPER ---
func _play_animation(anim_name: String) -> void:
	if dead or not sprite:
		return

	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

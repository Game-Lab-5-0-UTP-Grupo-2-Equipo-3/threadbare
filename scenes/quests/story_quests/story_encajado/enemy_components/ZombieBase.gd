extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 120.0
@export var damage: int = 10
@export var knockback_power: float = 300.0
@export var detection_radius: float = 250.0
@export var max_health: int = 50
@export var has_attack_animation: bool = false
@export var uses_run_animation: bool = false
@export var hurt_lock_time: float = 0.4  # 🕒 How long to pause after getting hit

var current_health: int
var player: Node2D = null
var attacking: bool = false
var dead: bool = false
var is_hurt: bool = false

signal enemy_died

@onready var attack_area: Area2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_timer: Timer = Timer.new()

func _ready() -> void:
	current_health = max_health
	add_child(hurt_timer)
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	
	print("🧟 Zombie spawned with health:", current_health)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	if hurt_box:
		hurt_box.area_entered.connect(_on_hurt_box_area_entered)
		print("✅ HurtBox connected for damage detection")
	else:
		print("⚠️ No HurtBox found — zombie won’t detect bullets")

func _physics_process(delta: float) -> void:
	if dead or is_hurt:
		move_and_slide()
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			print("🎯 Player found:", player.name)
		return

	var distance = global_position.distance_to(player.global_position)

	if attacking:
		_play_animation("attack")
		move_and_slide()
		return

	if distance <= detection_radius:
		_move_toward_player()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Flip sprite depending on direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

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

# --- ATTACK HANDLING ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if dead or is_hurt:
		return
	if body.is_in_group("Player"):
		print("💥 Attacked player:", body.name)
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
	print("🧨 Something entered hurtBox:", area.name)
	
	if area.is_in_group("PlayerProjectile") or area.is_in_group("bullet"):
		print("💫 Hit by projectile:", area.name)
		
		var dmg = 10
		if area.has_method("get_damage"):
			dmg = area.get_damage()
			print("🩸 Damage received:", dmg)
		
		take_damage(dmg)
		
		if area.has_method("queue_free"):
			print("🧹 Destroying projectile")
			area.queue_free()

func take_damage(amount: int) -> void:
	if dead:
		return
	current_health -= amount
	print("💔 Zombie took", amount, "damage → Health:", current_health)
	
	is_hurt = true
	velocity = Vector2.ZERO
	_play_animation("hurt")

	hurt_timer.start(hurt_lock_time)  # 🕒 Start short hurt pause

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
	print("☠️ Zombie died")
	emit_signal("enemy_died")
	await sprite.animation_finished
	queue_free()

# --- ANIMATION HELPER ---
func _play_animation(anim_name: String) -> void:
	if not sprite or dead:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

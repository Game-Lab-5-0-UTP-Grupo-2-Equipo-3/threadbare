# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends "res://scenes/game_elements/characters/player/components/player.gd"
class_name PlayerS

signal healthChanged
@onready var player_spriteS: AnimatedSprite2D = %PlayerSSprite

## The animations which must be provided by [member sprite_frames], each with the corresponding
## number of frames.
const REQUIRED_ANIMATION_FRAMES_S: Dictionary[StringName, int] = {
	&"idle": 2,
	&"idle_up": 2,
	&"idle_down": 2,
	&"walk": 4,
	&"walk_up": 4,
	&"walk_down": 4,
	&"hurt_down": 2,
	&"hurt_up": 2,
	&"hurt": 2,
	&"death":3,
	&"death_up":3,
	&"death_down":3,
}



@export var knockbackPower: float = 300.00

@export var maxHealth: int
@export var bullet_scene: PackedScene
@export var bullet_spawn_offset: float = 20.0
@export var shoot_cooldown: float = 0.25

@onready var currentHealth: int = maxHealth


@onready var hurtBox: Area2D = $HurtBox
@onready var hurtTimer: Timer = $hurtTimer


var isHurt: bool = false
var can_shoot: bool = true

func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode
	mode = new_mode
	if not is_node_ready():
		return
	# ---- KEEP ORIGINAL BEHAVIOR ----
	match new_mode:
		Mode.COZY:
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, false)
		Mode.FIGHTING:
			_toggle_player_behavior(player_fighting, true)
			_toggle_player_behavior(player_hook, false)
		Mode.HOOKING:
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, true)
		Mode.DEFEATED:
			_toggle_player_behavior(player_fighting, false)
			_toggle_player_behavior(player_hook, false)

	# ---- BUT FORCE INTERACTION TO ALWAYS BE ACTIVE ----
	player_interaction.visible = true
	player_interaction.process_mode = ProcessMode.PROCESS_MODE_INHERIT
		
	if mode != previous_mode:
		mode_changed.emit(mode)


func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	player_spriteS.sprite_frames = new_sprite_frames
	update_configuration_warnings()


func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	# Do NOT hide the node — hiding breaks Area2D monitoring
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)
# ✅ OVERRIDE: Disable parent’s strict animation checks
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	for animation: StringName in REQUIRED_ANIMATION_FRAMES_S:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)

	for animation: StringName in REQUIRED_ANIMATION_FRAMES_S:
		var count := sprite_frames.get_frame_count(animation)
		var expected_count := REQUIRED_ANIMATION_FRAMES_S[animation]
		if count != expected_count:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [animation, count, expected_count]
				)
			)

	return warnings




func _ready() -> void:
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)


func _unhandled_input(_event: InputEvent) -> void:
	var axis: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	var speed: float
	if player_hook.is_throwing_or_aiming():
		speed = aiming_speed
	elif Input.is_action_pressed(&"running"):
		speed = run_speed
	else:
		speed = walk_speed

	input_vector = axis * speed


## Returns [code]true[/code] if the player is running. When using an analogue joystick, this can be
## [code]false[/code] even if the player is holding the "run" button, because the joystick may be
## inclined only slightly.
func is_running() -> bool:
	# While walking diagonally with an analogue joystick, the input vector can be fractionally
	# greater than walk_speed, due to trigonometric/floating-point inaccuracy.
	return input_vector.length_squared() > (walk_speed * walk_speed) + 1.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# While pulling the grappling hook, the movement is handled in PlayerHook._process.
	if player_hook.pulling:
		return

	if player_interaction.is_interacting or mode == Mode.DEFEATED:
		velocity = Vector2.ZERO
		return

	var step := (
		stopping_step if velocity.length_squared() > input_vector.length_squared() else moving_step
	)
	velocity = velocity.move_toward(input_vector, step * delta)

	move_and_slide()


	if !isHurt:
		var overlapping_areas = hurtBox.get_overlapping_areas()
		for area in overlapping_areas:
			if area.name == "HitBox":
				hurt_by_melee(area)
			elif area.is_in_group("enemy_bullet"):
				hurt_by_bullet(area)
	
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func hurt_by_melee(hitbox: Area2D) -> void:
	currentHealth -= 10

	isHurt = true
	healthChanged.emit()

	if currentHealth <= 0:
		currentHealth = 0
		print("☠️ El jugador ha muerto")
		mode = Mode.DEFEATED

	var parent_enemy = hitbox.get_parent()
	if "velocity" in parent_enemy:
		knockback(parent_enemy.velocity)
	else:
		knockback(Vector2.ZERO)

	hurtTimer.start()
	await hurtTimer.timeout
	isHurt = false

func hurt_by_bullet(bullet: Area2D) -> void:
	currentHealth -= 10

	isHurt = true
	healthChanged.emit()

	if currentHealth <= 0:
		currentHealth = 0
		print("☠️ El jugador ha muerto")
		mode = Mode.DEFEATED

	if "velocity" in bullet:
		knockback(bullet.velocity)
	else:
		knockback(Vector2.ZERO)

	hurtTimer.start()
	await hurtTimer.timeout
	isHurt = false

func knockback(enemyVelocity: Vector2) -> void:
	var knockbackDirection: Vector2 = (enemyVelocity - velocity).normalized() * knockbackPower
	velocity = knockbackDirection
	move_and_slide()

func shoot():
	can_shoot = false
	
	var bullet = bullet_scene.instantiate()
	var dir = (get_global_mouse_position() - global_position).normalized()
	
	bullet.global_position = global_position + dir * bullet_spawn_offset
	bullet.direction = dir
	bullet.rotation = dir.angle()  # 🔥 rotate bullet to face shooting direction
	
	get_parent().add_child(bullet)
	
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
 

func teleport_to(
	tele_position: Vector2,
	smooth_camera: bool = false,
	look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED
) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()

	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = tele_position
		%PlayerSprite.look_at_side(look_side)
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = tele_position


func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value
	if not is_node_ready():
		await ready
	_walk_sound.stream = walk_sound_stream

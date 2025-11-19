# SPDX-FileCopyrightText: The Threadbare Authors 
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const REPEL_ANTICIPATION_TIME: float = 0.3

@onready var player: Player = owner
@onready var player_sprite: AnimatedSprite2D = %PlayerSSprite
@onready var player_fighting: Node2D = %PlayerFighting
@onready var player_hook: Node2D = %PlayerHook
@onready var original_speed_scale: float = speed_scale

var was_hurt : bool = false
var player_death : bool = false
var is_attacking: bool = false

func _ready() -> void:
	player.mode_changed.connect(_on_player_mode_changed)
	player_hook.string_thrown.connect(_on_player_hook_string_thrown)

func _process(_delta: float) -> void:
	if is_attacking:
		return
	
	match player.mode:
		Player.Mode.COZY:
			_process_walk_idle(_delta)
		Player.Mode.FIGHTING:
			_process_fighting(_delta)
		Player.Mode.HOOKING:
			_process_hooking(_delta)

	# Double speed when running
	var double_speed: bool = current_animation.begins_with("walk") and player.is_running()
	speed_scale = original_speed_scale * (2.0 if double_speed else 1.0)


# 🔹 Handles walking / idle / hurt logic
func _process_walk_idle(_delta: float) -> void:
	if player.isHurt:
		_process_hurt()
		return

	if player.velocity.is_zero_approx():
		play("idle")
	else:
		play("walk")


func _process_hurt() -> void:
	# Only play if not already playing
	if current_animation != "hurt":
		play("hurt")

	was_hurt = true


# 🔹 Handles death animations
func _process_death(_delta: float) -> void:
	if player_death:
		return
	player_death = true

	play("death")
	var anim := get_animation("death")
	if anim:
		anim.loop_mode = Animation.LOOP_NONE

	player.velocity = Vector2.ZERO


# 🔹 Handles fighting mode
func _process_fighting(delta: float) -> void:
	if player.isHurt:
		_process_hurt()
		return

	var repel: StringName = _get_repel_animation()

	if not player_fighting.is_fighting:
		if not (current_animation == repel and current_animation_position > REPEL_ANTICIPATION_TIME):
			_process_walk_idle(delta)
		return

	if current_animation != repel:
		play(repel)
		seek(REPEL_ANTICIPATION_TIME, false, false)


# 🔹 Handles hooking animation
func _process_hooking(delta: float) -> void:
	if player.isHurt:
		_process_hurt()
		return

	if current_animation == &"throw_string":
		return

	_process_walk_idle(delta)


func _get_repel_animation() -> StringName:
	return &"repel"


# 🔹 When player mode changes to defeated
func _on_player_mode_changed(mode: Player.Mode) -> void:
	if mode == Player.Mode.DEFEATED:
		_process_death(0.0)


# 🔹 When grappling hook is thrown
func _on_player_hook_string_thrown() -> void:
	if current_animation == &"throw_string":
		stop()
	play(&"throw_string")

func _on_player_shot_fired() -> void:
	is_attacking = true
	stop()
	play("attack")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		is_attacking = false

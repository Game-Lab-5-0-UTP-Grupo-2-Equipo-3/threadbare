extends AnimatedSprite2D

@onready var player: Player = owner
@onready var player_anim: AnimationPlayer = player.get_node("AnimationPlayer")

func _process(_delta: float) -> void:
	if not player:
		return
	if player.velocity.is_zero_approx():
		return

	var current_anim := player_anim.current_animation

	# ✅ Only flip for side animations
	if current_anim.ends_with("_up") or current_anim.ends_with("_down"):
		flip_h = false
	elif not is_zero_approx(player.velocity.x):
		flip_h = player.velocity.x < 0

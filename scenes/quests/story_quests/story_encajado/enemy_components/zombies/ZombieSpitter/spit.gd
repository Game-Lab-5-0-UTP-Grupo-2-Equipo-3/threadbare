extends Area2D
class_name Spit

@export var speed: float = 250.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var knockbackPower: float = 200.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Connect hit detection first!
	connect("area_entered", _on_area_entered)
	
	# Schedule auto-destruction
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
		rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if not area:
		return

	# Make sure we don’t hit other zombies
	if area.is_in_group("zombie") or area.name.contains("Zombie"):
		return

	# Check for player hurtbox
	if area.is_in_group("HurtBox") or area.is_in_group("hurtbox"):
		var player = area.get_parent()
		if player and player.has_method("hurtByEnemy"):
			print("💦 Spit hit player!")
			player.hurtByEnemy(self)
			queue_free()

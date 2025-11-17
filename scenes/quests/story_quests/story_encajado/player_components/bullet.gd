extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("PlayerProjectile")
	set_process(true)
	$CollisionShape2D.disabled = false
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Automatically delete bullet after some time
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _process(delta: float) -> void:
	position += direction * speed * delta


func get_damage() -> int:
	return damage


func _on_area_entered(area: Area2D) -> void:
	# Optionally handle area collision (e.g., with enemy hurtboxes)
	if area.is_in_group("Enemy"):
		_hit_target(area)


func _on_body_entered(body: Node2D) -> void:
	# Handle body collision (zombies are CharacterBody2D)
	if body.is_in_group("Enemy"):
		_hit_target(body)


func _hit_target(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()

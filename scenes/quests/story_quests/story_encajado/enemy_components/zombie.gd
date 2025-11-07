extends CharacterBody2D

@export var move_speed: float = 120.0
@export var damage: int = 10
@export var knockback_power: float = 300.0
@export var detection_radius: float = 250.0

var player: Node2D = null

@onready var attack_area: Area2D = $hitBox

func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= detection_radius:
		_move_toward_player(delta)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _move_toward_player(delta: float) -> void:
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.hurtByEnemy(self)

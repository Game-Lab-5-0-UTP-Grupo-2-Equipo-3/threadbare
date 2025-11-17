extends Area2D

@export var speed = 2000

var direction := Vector2.ZERO
var velocity := Vector2.ZERO

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		velocity = direction * speed
		rotation=direction.angle()
		global_position +=velocity

func set_direction(direction:Vector2):
	self.direction = direction


func _on_area_entered(area: Area2D) -> void:
	if area.name=="Bullet":
		queue_free() # Replace with function body.

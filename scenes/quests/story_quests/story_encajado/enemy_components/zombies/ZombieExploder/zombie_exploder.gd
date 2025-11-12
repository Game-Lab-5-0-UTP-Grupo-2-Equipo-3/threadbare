extends ZombieBase
class_name ZombieExploder

@export var explosion_radius: float = 100.0
@export var explosion_damage: int = 25

func _ready() -> void:
	move_speed = 90.0
	max_health = 50
	damage = 0 
	detection_radius = 250.0
	has_attack_animation = true  

	super._ready()
	print("💥 Exploder zombie ready — kamikaze type")

func die() -> void:
	print("💣 Exploder detonated!")
	_explode()
	super.die()

func _explode() -> void:
	var bodies = get_overlapping_bodies_in_radius(explosion_radius)
	for body in bodies:
		if body.is_in_group("Player"):
			body.hurtByExplosion(explosion_damage)
	print("🔥 Explosion hit", bodies.size(), "entities")

func get_overlapping_bodies_in_radius(radius: float) -> Array:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_shape(query)
	
	var colliders: Array = []
	for r in result:
		if r.has("collider"):
			colliders.append(r.collider)
	
	return colliders

extends Node2D
class_name ObstacleManager

@export var obstacles: Array[PackedScene] = []
@export var amount: int = 20
@export var spawn_area: Rect2
@export var min_spacing: float = 60.0
@export var tries_per_spawn: int = 12

@onready var container := $obstacles_container
var generated := false

func _ready():
	await get_tree().process_frame
	generate()


func generate():
	if generated:
		return
	generated = true

	randomize()

	while container.get_child_count() < amount:
		try_spawn()


func try_spawn():
	for i in range(tries_per_spawn):
		var scene: PackedScene = obstacles.pick_random()
		var pos: Vector2 = get_random_pos()

		if is_free(pos):
			spawn_obstacle(scene, pos)
			return

	print("❌ No free position found for this spawn attempt")


func spawn_obstacle(scene: PackedScene, pos: Vector2):
	var inst = scene.instantiate()
	container.add_child(inst)
	inst.global_position = pos


func get_random_pos() -> Vector2:
	return Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)


func is_free(pos: Vector2) -> bool:
	for child in container.get_children():
		if child.global_position.distance_to(pos) < min_spacing:
			return false
	return true

extends Node2D
class_name ObstacleManager

@export var obstacles: Array[PackedScene] = []  # obstacle scenes
@export var amount: int = 20                   # how many obstacles to spawn
@export var spawn_area: Rect2                  # where they can appear
@export var min_spacing: float = 60.0          # avoid collisions
@export var tries_per_spawn: int = 12

@onready var container := $obstacles_container
var generated := false

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
		print("Testing pos:", pos, "free?", is_free(pos))

		if is_free(pos):
			print("Spawning at:", pos)
			spawn_obstacle(scene, pos)
			return

	print("❌ No free position found this attempt")




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
	var space := get_world_2d().direct_space_state

	var res = space.intersect_circle(
		pos,
		min_spacing,
		{
			"collision_mask": 1, # adjust to match obstacles' layer
			"max_results": 1
		}
	)

	return res.is_empty()

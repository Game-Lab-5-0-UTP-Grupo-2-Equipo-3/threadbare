extends Node2D

# --- CONFIGURATION ---
@export var zombie_scenes: Array[PackedScene]
@export var enemies_per_wave: Array[int] = [3, 5, 8, 12, 16]
@export var time_between_spawns: float = 1.0
@export var time_between_waves: float = 5.0

# --- SPAWN POINTS ---
@onready var spawn_points: Array[Node2D] = [
	$SpawnNorth,
	$SpawnSouth,
	$SpawnEast,
	$SpawnWest
]

# --- INTERNAL STATE ---
var current_wave: int = 0
var enemies_alive: int = 0
var spawning_wave: bool = false


# --- MAIN ---
func _ready() -> void:
	if zombie_scenes.is_empty():
		push_warning("⚠️ No zombie scenes assigned to EnemyManager!")
	start_next_wave()


# --- WAVE MANAGEMENT ---
func start_next_wave() -> void:
	if current_wave >= enemies_per_wave.size():
		print("✅ All waves completed! 🎉")
		return

	current_wave += 1
	print("🧨 Starting wave", current_wave)
	spawning_wave = true
	spawn_wave(enemies_per_wave[current_wave - 1])


func spawn_wave(enemy_count: int) -> void:
	for i in range(enemy_count):
		spawn_enemy()
		await get_tree().create_timer(time_between_spawns).timeout
	spawning_wave = false


# --- ENEMY SPAWNING ---
func spawn_enemy() -> void:
	if spawn_points.is_empty() or zombie_scenes.is_empty():
		push_warning("⚠️ Missing spawn points or zombie scenes!")
		return

	var spawn_point = spawn_points.pick_random()
	var zombie_scene = zombie_scenes.pick_random()
	var zombie = zombie_scene.instantiate()

	zombie.global_position = spawn_point.global_position
	add_child(zombie)
	enemies_alive += 1

	print("🧟 Spawned:", zombie.name, "from", spawn_point.name)

	# Connect to death signal to track active count
	if zombie.has_signal("enemy_died"):
		zombie.enemy_died.connect(_on_enemy_died.bind(zombie))


# --- ON ENEMY DEATH ---
func _on_enemy_died(zombie: Node) -> void:
	enemies_alive -= 1
	print("☠️ Zombie died. Remaining:", enemies_alive)
	
	# Cleanup (safety)
	if is_instance_valid(zombie):
		zombie.queue_free()

	# If wave cleared, start next
	if enemies_alive <= 0 and not spawning_wave:
		print("🌊 Wave", current_wave, "cleared!")
		await get_tree().create_timer(time_between_waves).timeout
		start_next_wave()

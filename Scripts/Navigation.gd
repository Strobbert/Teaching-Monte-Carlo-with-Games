extends Node

var grid: TileMapLayer
var region: Rect2i
var rng: RandomNumberGenerator


func set_up(tml: TileMapLayer, seed_val: int) -> void:
    grid = tml
    region = grid.get_used_rect()
    if seed_val > 0:
        seed(seed_val)
    rng = RandomNumberGenerator.new()

func world_to_grid(pos:Vector2) -> Vector2i:
    return grid.local_to_map(pos)

func grid_to_world(tile: Vector2i) -> Vector2:
    return grid.map_to_local(tile)

func clamp_to_grid(pos: Vector2i) -> Vector2i:
    return Vector2i(clampi(pos.x, 0, region.size.x - 1), clampi(pos.y, 0, region.size.y - 1))

func get_random_cornor() -> Vector2i:
    return Vector2i(randi_range(0,1) * (region.size.x - 1), randi_range(0,1) * (region.size.y - 1)) 

func get_random_tile(space: Rect2i = region) -> Vector2i:
    return clamp_to_grid(Vector2i(randi_range(0, space.size.x - 1), randi_range(0, space.size.y - 1))) + space.position

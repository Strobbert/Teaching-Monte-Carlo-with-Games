class_name Tile
extends Node

var arrows: AnimatedSprite2D
var policy: Array[Directions.Dir] = []
@onready var up: Sprite2D = $Up
@onready var right: Sprite2D = $Right
@onready var down: Sprite2D = $Down
@onready var left: Sprite2D = $Left

func toggle_direction(dir: Direction.Dir) -> void:
    var index = policy.find(dir)
    if index > -1:
        get_sprite(dir).visible = false
        policy.remove_at(index)
    else:
        get_sprite(dir).visible = true
        policy.append(dir)

func clear_policy() -> void:
    for dir in policy:
        get_sprite(dir).visible = false
    policy.clear()

func get_sprite(dir: Directions.Dir) -> Sprite2D:
    match dir:
        Directions.Dir.Up:
            return up
        Directions.Dir.Right:
            return right
        Directions.Dir.Down:
            return down
        Directions.Dir.Left:
            return left
    return null

func get_random_move() -> Vector2i:
    if policy.is_empty():
        return Vector2i.ZERO
    var move: Directions.Dir = policy.pick_random()
    return Directions.to_vector(move)

func has_policy() -> bool:
    return policy.size() != 0

class_name Direction
extends Node

enum Dir{
    Up =0,
    Right=1,
    Down=2,
    Left=3
}

func to_vector(move: Dir) -> Vector2i:
    match move:
        Dir.Up:
            return Vector2i.UP
        Dir.Right:
            return Vector2i.RIGHT
        Dir.Down:
            return Vector2i.DOWN
        Dir.Left:
            return Vector2i.LEFT
        _:
            return Vector2i.ZERO
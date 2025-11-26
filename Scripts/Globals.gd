extends Node

const step_value: int = -1
const yellow_value: int = 0
const red_value: int = -3
const end_value: int = 30

func to_array() -> Array[int]:
    return [step_value, yellow_value, red_value, end_value]
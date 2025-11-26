extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

func change_scene(target_scene: String) -> void:
	anim.play("Fade_in")
	await anim.animation_finished
	get_tree().change_scene_to_file(target_scene)
	anim.play_backwards("Fade_in")
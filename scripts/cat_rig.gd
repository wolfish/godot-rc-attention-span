extends Node2D

signal cat_appear_finished

func _on_animation_player_finished(anim_name: StringName) -> void:
	cat_appear_finished.emit()

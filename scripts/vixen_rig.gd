extends Node2D

var footstep: int = 1
var blink_on: bool = false

func set_main_target(target: Node2D) -> void:
	$OpenEyes/EyeOpenLeft/Polygon2D/VixenEye.set_target(target)
	$NarrowEyes/EyeNarrowLeft/Polygon2D/VixenEye.set_target(target)
	$SlimEyes/EyeSlimLeft/Polygon2D/VixenEye.set_target(target)


func _on_footstep_timer_timeout() -> void:
	if footstep == 1:
		$Footstep1.play()
		footstep = 2
	elif footstep == 2:
		$Footstep2.play()
		footstep = 1


func _on_blink_animation_finished(anim_name: StringName) -> void:
	if !blink_on:
		blink_on = true
		$BlinkAnimation.play_backwards("blink")
		return
	if blink_on:
		blink_on = false

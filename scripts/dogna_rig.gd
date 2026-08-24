extends Node2D

var blink_revert: bool = false

signal blink_completed
signal eyeroll_completed


func set_main_target(target: Node2D) -> void:
	$Eyes/Bored/LeftEyeOpen/LeftEye/DognaEyeLeft.set_target(target)
	$Eyes/Bored/RightEyeBored/RightEye/DognaEyeRight.set_target(target)
	$Eyes/Narrow/LeftEyeOpen/LeftEye/DognaEyeLeft.set_target(target)
	$Eyes/Narrow/RightEyeNarrow/RightEye/DognaEyeRight.set_target(target)
	$Eyes/OpenNormal/LeftEyeOpen/LeftEyeFullOpen/DognaEyeLeft.set_target(target)
	$Eyes/OpenNormal/RightEyeOpen/RightEyeFullOpen/DognaEyeRight.set_target(target)


func toggle_arms() -> void:
	$LeftArm.visible = !$LeftArm.visible
	$RightArm.visible = !$RightArm.visible
	$LeftHand.visible = !$LeftHand.visible
	$RightHand.visible = !$RightHand.visible


func _on_blink_animation_finished(anim_name: StringName) -> void:
	if anim_name != 'blink':
		return
	if !blink_revert:
		blink_revert = true
		$BlinkAnimation.play_backwards("blink")
		return
	if blink_revert:
		blink_revert = false
		blink_completed.emit()


func _on_blink_animation_started(anim_name: StringName) -> void:
	if !blink_revert:
		$BlinkSound.play()


func _on_tapping_timer_timeout() -> void:
	$Tapping.play()
	$TappingTimer.wait_time = randf_range(0.2, 0.5)
	$TappingTimer.start()


func _on_face_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'eyeroll':
		eyeroll_completed.emit()

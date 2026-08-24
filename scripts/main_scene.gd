extends Node2D

var reading_eye_count: int = 0
var phone_toggled: bool = false
var vixen_in: bool = false
var music_position: float = 0.0


func _ready() -> void:
	$DognaRig.connect("blink_completed", _on_blink_completed)
	$DognaRig.connect("eyeroll_completed", _on_eyeroll_completed)
	$CatRig.connect("cat_appear_finished", _on_flicker_start)


func _phone_glitch() -> void:
	$PhoneIdle/GlitchShader.visible = true
	$Audio/PinkNoise.play()
	await get_tree().create_timer(1.0).timeout
	$PhoneAnimation.play('vibrate')
	$Audio/PhoneVibrate.play()
	$Audio/PinkNoise.stop()
	$PhoneIdle/GlitchShader.visible = false
	$PhoneIdle.texture = load("res://sprites/phone_notify.png")
	$PhoneIdle/PhoneBacklight.visible = true
	$PhoneIdle/PhoneShine.visible = true
	$Audio/PhoneNotify.play()
	$DognaRig/Eyes/OpenNormal/LeftEyeOpen.visible = true
	$DognaRig/Eyes/Bored.visible = false
	$DognaRig/Eyes/Bored/RightEyeBored.visible = true
	$DognaRig.set_main_target($PhoneIdle)
	$Audio/Ambient.stop()
	await get_tree().create_timer(1.0).timeout
	$DognaRig/Mouth.texture = load('res://sprites/dogna/body/mouth_ajar.png')
	$DognaRig/Mouth.flip_h = false
	$DognaRig/MouthOpen.play()
	await get_tree().create_timer(1.0).timeout
	$Chair/ChairRoll.play()
	$PhoneAnimation.play("phone_in")


func _on_flicker_start() -> void:
	$Audio/Flicker.play()
	$ReadingAnimation.stop()
	$ReadingEyeChangeTimer.stop()
	$FlickerAnimation.play("flicker")
	await get_tree().create_timer(0.2).timeout
	$DognaRig/QuestionSound.play()


func _on_blink_completed() -> void:
	if !phone_toggled:
		$ReadingAnimation.play("dogna_read")
		$ReadingEyeChangeTimer.start()


func _on_eyeroll_completed() -> void:
	$ReadingAnimation.play("dogna_read")


func _on_reading_eye_change_timer_timeout() -> void:
	reading_eye_count += 1
	match (reading_eye_count):
		2:
			$DognaRig/Eyes/OpenNormal.visible = false
			$DognaRig/Eyes/Bored.visible = true
			$Audio/EyesBored.play()
		1:
			$DognaRig/BlinkAnimation.play('blink')
			$ReadingAnimation.pause()
			$ReadingEyeChangeTimer.stop()
		4:
			$DognaRig/Eyes/Bored.visible = false
			$DognaRig/Eyes/Narrow.visible = true
			$ReadingEyeChangeTimer.stop()
			$CatRig.visible = true
			$Audio/EyesBored.play()
			$CatRig/AnimationPlayer.play('cat_appear')
			$Audio/Music.stream_paused = true
			$Audio/Ambient.play()


func _on_flicker_animation_finished(anim_name: StringName) -> void:
	$Audio/Flicker.stop()


func _on_flicker_animation_started(anim_name: StringName) -> void:
	$DognaRig.set_main_target($MainLight)


func _on_phone_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'phone_in' and !phone_toggled:
		$Chair/ChairRoll.stop()
		$PhoneIdle.visible = false
		$PhoneIdle/PhoneBacklight.visible = false
		$PhoneIdle/PhoneShine.visible = false
		$PhoneIdle.texture = load('res://sprites/phone_idle.png')
		$DognaRig.toggle_arms()
		$DognaRig/PhoneArms.visible = true
		$DognaRig/Mouth.visible = false
		$DognaRig/MouthTounge.visible = true
		$DognaRig/Tounge.visible = true
		$PhoneAnimation.play('phone_play')
		$DognaRig/FaceAnimation.play('tounge_toggle')
		phone_toggled = true
		$BlinkTimer.start()
		$DognaRig/TappingTimer.start()
		$VixenTimer.start()
	elif anim_name == 'phone_in' and phone_toggled:
		$Chair/ChairRoll.stop()
		$ReadingAnimation.play('dogna_read')
		phone_toggled = false


func _on_blink_timer_timeout() -> void:
	$DognaRig/BlinkAnimation.play('blink')


func _on_vixen_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'walk_in' and vixen_in:
		$VixenRig/FootstepTimer.stop()
		$Audio/DoorClose.play()
		$Audio/Music.stream_paused = true
		$DognaRig/Eyes/OpenNormal.visible = false
		$DognaRig/Eyes/Bored.visible = false
		$DognaRig/Eyes/Closed.visible = true
		$DognaRig/Eyes/ClosedHappy.visible = true
		$DognaRig/Eyes/Closed/LeftEyeClosed.visible = false
		$DognaRig/Eyes/ClosedHappy/RightEyeClosed.visible = false
		$DognaRig/Mouth.flip_h = false
		$DognaRig/Mouth.texture = load('res://sprites/dogna/body/mouth_frown.png')
		await get_tree().create_timer(1.5).timeout
		$DognaRig/Eyes/Closed.visible = false
		$DognaRig/Eyes/ClosedHappy.visible = false
		$DognaRig/Eyes/Closed/LeftEyeClosed.visible = true
		$DognaRig/Eyes/ClosedHappy/RightEyeClosed.visible = true
		$DognaRig/Eyes/Bored.visible = true
		$DognaRig/Eyes/Bored/LeftEyeOpen.visible = true
		$DognaRig/Eyes/Bored/RightEyeBored.visible = true
		$DognaRig/Mouth.flip_h = true
		$DognaRig/Mouth.texture = load('res://sprites/dogna/body/mouth_front_tooth.png')
		await get_tree().create_timer(1.5).timeout
		$DognaRig/Eyes/Bored.visible = false
		$DognaRig/Eyes/OpenNormal.visible = true
		$DognaRig/Eyes/OpenNormal/LeftEyeOpen.visible = true
		$DognaRig/Eyes/OpenNormal/RightEyeOpen.visible = true
		$Audio/Music.stream_paused = false
		$DognaRig/FaceAnimation.play('eyeroll')
		await get_tree().create_timer(1.5).timeout
		$Clipboard/ClipboardAnimation.play('show')
		return
	if anim_name == 'walk_in' and !vixen_in:
		$VixenRig/FootstepTimer.stop()
		vixen_in = true
		$DognaRig.set_main_target($VixenRig/Face)
		$VixenRig.set_main_target($DognaRig/PhoneMarker)
		$VixenRig/BlinkAnimation.play('blink')
		await get_tree().create_timer(1.0).timeout
		$VixenRig.set_main_target($DognaRig/FaceMarker)
		$VixenRig/OpenEyes/EyeOpenRight.visible = false
		$VixenRig/NarrowEyes.visible = true
		$VixenRig/NarrowEyes/EyeNarrowLeft.visible = false
		$DognaRig/FaceAnimation.play_backwards("tounge_toggle")
		$DognaRig/BlinkAnimation.play('blink')
		$DognaRig/TappingTimer.stop()
		$PhoneAnimation.stop()
		$Audio/Music.play($Audio/Music.get_playback_position() + 1.0)
		await get_tree().create_timer(1.5).timeout
		$DognaRig/MouthTounge.visible = false
		$DognaRig/Tounge.visible = false
		$DognaRig/MouthSmile.visible = true
		$DognaRig/Eyes/OpenNormal.visible = false
		$DognaRig/Eyes/ClosedHappy.visible = true
		$DognaRig/SmileSound.play()
		await get_tree().create_timer(1).timeout
		$DognaRig.toggle_arms()
		$DognaRig/PhoneArms.visible = false
		$PhoneIdle.visible = true
		$Audio/PhoneDown.play()
		await get_tree().create_timer(1.5).timeout
		$DognaRig/Eyes/ClosedHappy.visible = false
		$DognaRig/Eyes/Bored.visible = true
		$PhoneAnimation.play_backwards("phone_in")
		$Chair/ChairRoll.play()
		$DognaRig/Mouth.texture = load('res://sprites/dogna/body/mouth_front_tooth.png')
		$DognaRig/Mouth.flip_h = true
		$VixenRig/OpenEyes/EyeOpenRight.visible = true
		$VixenRig/NarrowEyes/EyeNarrowLeft.visible = true
		$VixenRig/NarrowEyes.visible = false
		await get_tree().create_timer(3).timeout
		$DognaRig/MouthSmile.visible = false
		$DognaRig/Mouth.visible = true
		$VixenLeaveTimer.start()


func _on_vixen_timer_timeout() -> void:
	$Audio/DoorOpen.play()
	$VixenRig/FootstepTimer.start()
	$VixenAnimation.play('walk_in')
	$VixenRig.set_main_target($DognaRig/FaceMarker)


func _on_vixen_leave_timer_timeout() -> void:
	$VixenRig/FootstepTimer.start()
	$VixenRig.set_main_target($DoorMarker)
	$VixenAnimation.play_backwards('walk_in')
	await get_tree().create_timer(1).timeout
	$VixenRig/BlinkAnimation.play('blink')
	$ReadingAnimation.stop()
	$DognaRig/Eyes/OpenNormal.visible = true
	$DognaRig/Eyes/OpenNormal/RightEyeOpen.visible = false
	$DognaRig/Eyes/Bored/LeftEyeOpen.visible = false
	$DognaRig.set_main_target($VixenRig/Face)

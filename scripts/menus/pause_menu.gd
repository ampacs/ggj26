extends Control

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	pause_game()

func pause_game() -> void:
	if Input.is_action_just_pressed("pause_game"):
		if get_tree().paused:
			resume()
		else:
			pause()
			
func resume() -> void:
	get_tree().paused = false
	visible = false
	
func pause() -> void:
	get_tree().paused = true
	visible = true

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

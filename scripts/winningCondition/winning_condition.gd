extends Node

@onready var final_game_menu := $FinalGameMenu as Control
@onready var quit_button := $FinalGameMenu/Panel/VBoxContainer/Quit as TextureButton
@onready var winner_player_label := $FinalGameMenu/Panel/VBoxContainer/Label as Label
@onready var restart_button:= $FinalGameMenu/Panel/VBoxContainer/Restart as TextureButton
@onready var victory_sfx:= $victorySfx as AudioStreamPlayer

func _on_winning_area_game_won(playerId: String) -> void:
	self.victory_sfx.play()
	final_game_menu.visible = true
	get_tree().paused
	
	await get_tree().process_frame
	winner_player_label.text = playerId + " won!"
	restart_button.grab_focus()

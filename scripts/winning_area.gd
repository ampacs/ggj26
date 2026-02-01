extends Area3D

@onready var victory_sfx: AudioStreamPlayer = $"../victorySfx"

signal game_won

func _on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body is PlayerController:
		var player := body as PlayerController
		if player.hasMaskEquipped:
			self.victory_sfx.play()
			emit_signal("game_won", player.playerId)

extends Area3D

signal game_won

func _on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body is PlayerController:
		var player := body as PlayerController
		if player.hasMaskEquipped:
			emit_signal("game_won", player.playerId)

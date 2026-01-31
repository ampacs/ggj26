extends Node

var debuffs := []

func add_debuff(type: String) -> void:
	debuffs.append(type)
	
func remove_debuff(type: String) -> void:
	debuffs.erase(type)
	
func has_debuff(type: String) -> bool:
	return debuffs.has(type)

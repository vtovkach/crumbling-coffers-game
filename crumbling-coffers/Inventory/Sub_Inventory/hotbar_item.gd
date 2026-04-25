extends Resource

class_name HotbarItem

enum TargetMode {
	NONE,
	GROUP_EXCLUDING_USER,
	GROUP_INCLUDING_USER,
	USER_ONLY
}

@export var name: String = ""
@export var texture: Texture2D

# Stable id used by networking/server messages instead of relying on resource paths.
@export var item_id: String = ""

# Data-driven use behavior. This keeps Hotbar.gd from hard-coding specific item files.
@export var effect_method: StringName = &""
@export var target_group: StringName = &""
@export var target_mode: TargetMode = TargetMode.NONE
@export var duration: float = 0.0
@export var multiplier: float = 1.0
@export var consumed_on_use: bool = true

func can_use() -> bool:
	return effect_method != &""

func build_use_request(user: Node = null) -> Dictionary:
	return {
		"item_id": item_id,
		"item_name": name,
		"effect_method": effect_method,
		"target_group": target_group,
		"target_mode": target_mode,
		"duration": duration,
		"multiplier": multiplier,
		"consumed_on_use": consumed_on_use,
		"user": user
	}

# Auto-generated Memokeeper Registry - Layers (core)

class_name Layers

const DEBUG: LayerEntry = preload("res://data/core/layers/debug.tres")
const GAME: LayerEntry = preload("res://data/core/layers/game.tres")
const HUD: LayerEntry = preload("res://data/core/layers/hud.tres")
const MENU: LayerEntry = preload("res://data/core/layers/menu.tres")
const TRANSITION: LayerEntry = preload("res://data/core/layers/transition.tres")

static var ALL: Array[LayerEntry] = [DEBUG, GAME, HUD, MENU, TRANSITION]

static func get_all() -> Array[LayerEntry]:
    return ALL

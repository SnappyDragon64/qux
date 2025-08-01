# Qux: A Godot 4 Game Framework Foundation

## 1. Overview

Qux is a foundational framework for Godot 4 projects, designed to promote a structured, data-driven, and scalable approach to game development. It provides a suite of robust managers, a powerful automatic resource registry system, and clear conventions for organizing game assets and logic.

## 2. Core Features

### 2.1. Data-Driven Design

The framework heavily emphasizes defining game entities and configurations as Godot `Resource` files (`.tres`). This allows for easy modification and extension of game data without deep code changes.

*   **Resource Definitions:** Custom resource types are defined in `core/definitions/`. These are simple data containers:
	*   `EventEntry`: Defines an event, including an optional data schema for payload validation.
	*   `LayerEntry`: Defines a named `CanvasLayer` with a specific Z-index.
	*   `SceneEntry`: Defines a game scene by linking to its `.tscn` file and its associated `LayerEntry`.
	*   `SceneSetEntry`: Defines a logical group of scenes (an array of `SceneEntry` resources) that should be active at the same time.
	*   `TransitionEntry`: Defines a visual transition by linking to a `SceneEntry` that points to the transition's scene.
*   **Data Location:** These resource instances are typically stored in `data/core/` for framework-level entities and `data/game/` for game-specific entities.

### 2.2. AutoRegistry System

The AutoRegistry system is an editor plugin (`addons/autoregistry/`) that automates the creation of static GDScript classes providing preloaded access to all defined resources.

*   **Functionality:**
	*   **Recursive Scanning:** The generator **recursively scans** predefined directories (e.g., `res://data/core/scenes/`). This allows you to organize your resource files into any nested subdirectory structure you want.
	*   For each top-level data folder (e.g., `events`, `scenes`), it generates a corresponding GDScript class (e.g., `Events.gd`, `Scenes.gd`).
	*   **Descriptive Naming:** It generates `const` members where the name is derived from the resource's full path. A file at `scenes/levels/world_1/hub.tres` will become `Scenes.LEVELS_WORLD_1_HUB`.
	*   The type of the constant is inferred from the first resource found in the directory tree. **All resources within a given tree (e.g., `scenes`) must be of the same type.**
	*   Each generated class also includes a static `ALL` array and a `get_all()` method to easily access all resources of that type.
*   **Generated Output:**
	*   For the "Core" registry configuration (`data/core/`), files are generated in `core/registry/`.
	*   For the "Game" registry configuration (`data/game/`), files are generated in `game/registry/`.
*   **Benefits:**
	*   **Organizational Freedom:** Structure your data files in logical subdirectories.
	*   **Type Safety & Discoverability:** Access resources through typed, autocompletable constants (e.g., `Scenes.UI_MAIN_MENU`).
	*   **Performance:** Resources are preloaded, avoiding runtime `load()` overhead.
	*   **Maintainability:** The generator automatically updates references when files are moved or renamed.
*   **Automatic Regeneration:** The plugin monitors the filesystem for changes and automatically regenerates registries with a debounce timer.

### 2.3. Manager Singletons (Autoloads)

A set of singleton managers, configured as autoloads in `project.godot`, provide the core runtime logic for the framework.

*   **`LayerManager` (`core/managers/layer_manager.gd`):**
	*   Responsible for creating and managing `CanvasLayer` nodes based on `LayerEntry` resources.
	*   Provides a `get_layer(layer_entry: LayerEntry)` method to retrieve a specific `CanvasLayer`.

*   **`SceneManager` (`core/managers/scene_manager.gd`):**
	*   The low-level authority for the lifecycle of individual scenes. It handles loading, unloading, and tracking all scene instances.
	*   **Asynchronous API:** The manager provides a robust, non-blocking API for loading scenes.
	*   `load_scene(scene_entry: SceneEntry) -> Callable`: **This is the primary loading function.** It initiates the loading process and **immediately returns a `Callable` object**, which represents the in-progress task. It does *not* return the scene node directly. To get the scene node, you must `await` the returned Callable.
	*   `load_scene_deferred(scene_entry: SceneEntry) -> void`: A "fire-and-forget" method that starts the loading process in the background. Use this for pre-loading non-critical scenes.
	*   `unload_scene(scene_entry: SceneEntry)`: Safely removes and frees the instance of the specified scene.
	*   `get_scene(scene_entry: SceneEntry)`: Retrieves the root node of an already loaded scene.
	*   `is_scene_loaded(scene_entry: SceneEntry)`: Checks if a scene is currently tracked as loaded.

*   **`EventBus` (`core/managers/event_bus.gd`):**
	*   A global event system for decoupled communication between different parts of the application.
	*   It dynamically creates signals based on `EventEntry` resources and can validate event data against a defined schema.
	*   `subscribe(event_entry, callable)`, `unsubscribe(event_entry, callable)`, `publish(event_entry, data)`, `wait_for(event_entry)`.

*   **`SceneSetManager` (`core/managers/scene_set_manager.gd`):**
	*   The high-level orchestrator for managing game states. It operates on `SceneSetEntry` resources to control which scenes are active.
	*   `change_set(new_set_entry: SceneSetEntry)`: This is the core function for transitioning between states (e.g., from a menu to a level). It follows a safe and efficient sequence:
		1.  It engages a **state lock** to prevent multiple transitions from running at once.
		2.  It uses the `TransitionManager` to play an "intro" animation.
		3.  It unloads all scenes of the previous set.
		4.  It **concurrently loads** all scenes for the new set, waiting for them all to complete for maximum efficiency.
		5.  Once all new scenes are ready, it plays an "outro" animation to reveal the new state.

*   **`TransitionManager` (`core/managers/transition_manager.gd`):**
	*   Manages the visual animations between `SceneSet` changes.
	*   **On-Demand Loading:** The `TransitionManager` does not preload transitions. A transition's scene must be loaded via the `SceneManager` *before* it is set as the active transition.
	*   `set_current_transition(transition_entry: TransitionEntry) -> bool`: Assigns the transition to be used for the next state change. It validates that the underlying scene is loaded and is a proper `Transition` node.
	*   `play_intro()` / `play_outro()`: Plays the respective animations on the current transition node. These are typically called only by the `SceneSetManager`.

### 2.4. Transition System

Reusable screen transitions are implemented using a custom `Transition` node.

*   **`Transition` Node (`core/nodes/transition.gd`):**
	*   A `Control` node designed to host transition animations.
	*   Requires an `AnimationPlayer` child node with animations named "intro" and "outro".
	*   The script is marked `@tool` and provides editor warnings if the required `AnimationPlayer` or animations are missing.

### 2.5. Core/Game Directory Split

The project structure encourages a separation between the core framework and game-specific logic and assets. This split helps in keeping the framework reusable and the game logic organized.

*   **`core/` Directory:** Contains foundational, game-agnostic code (managers, base nodes, core resource definitions).
*   **`game/` Directory:** Intended for all game-specific scenes, scripts, assets, and registry definitions.

## 3. Project Structure Highlights

```
qux/
├── .godot/ # Godot internal project data
├── addons/
│ └── autoregistry/ # AutoRegistry plugin
├── core/
│ ├── definitions/ # Scripts for custom Resource types
│ ├── managers/ # Autoloaded manager scripts
│ ├── nodes/ # Custom node scripts
│ └── registry/ # AUTOGENERATED registry classes for core resources
├── data/
│ ├── core/ # .tres files for core framework (can have subdirectories)
│ │ ├── events/
│ │ ├── layers/
│ │ └── scenes/
│ └── game/ # .tres files for game data (can have subdirectories)
│ └── ...
├── game/
│ └── registry/ # AUTOGENERATED registry classes for game resources
├── project.godot
└── README.md
```
## 4. Usage

1.  **Define Resources:** Create `.tres` files and organize them in any subdirectory structure you like within `data/core/` or `data/game/`. For example: `data/game/scenes/levels/world_1/hub.tres`.
2.  **AutoRegistry Generation:** The plugin will automatically generate a corresponding constant, e.g., `GameScenes.LEVELS_WORLD_1_HUB`.
3.  **Utilize Managers:**
	*   Load a scene and wait for it: `var my_node = await SceneManager.load_scene(GameScenes.LEVELS_WORLD_1_HUB)`.
	*   Load a scene in the background: `SceneManager.load_scene_deferred(GameScenes.PLAYER_CHARACTER)`.
	*   Change the entire game state: `SceneSetManager.change_set(GameSceneSets.CHAPTER_1)`.
	*   Prepare a transition: First, load its scene (`await SceneManager.load_scene(...)`), then set it (`TransitionManager.set_current_transition(...)`).
4.  **Event-Driven Communication:**
	*   Define event types: Create `EventEntry` resources (e.g., `GameEvents.GAMEPLAY_PLAYER_DIED`).
	*   Publish events: `EventBus.publish(GameEvents.GAMEPLAY_PLAYER_DIED, {"score": 100})`.
	*   Subscribe to events: `EventBus.subscribe(GameEvents.GAMEPLAY_PLAYER_DIED, on_player_died)`.
5.  **Develop Game Logic:** Implement game-specific scenes and scripts primarily within the `game/` directory.

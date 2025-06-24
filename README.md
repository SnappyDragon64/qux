# Qux: A Godot 4 Game Framework Foundation

## 1. Overview

Qux is a foundational framework for Godot 4 projects, designed to promote a structured, data-driven, and scalable approach to game development. It provides a suite of managers, a powerful automatic resource registry system, and conventions for organizing game assets and logic.

## 2. Core Features

### 2.1. Data-Driven Design

The framework heavily emphasizes defining game entities and configurations as Godot `Resource` files (`.tres`). This allows for easy modification and extension of game data without deep code changes.

*   **Resource Definitions:** Custom resource types are defined in `core/definitions/`:
    *   `EventEntry`: Defines an event, including an optional data schema for payload validation.
    *   `LayerEntry`: Defines a named `CanvasLayer` with a specific Z-index.
    *   `SceneEntry`: Defines a game scene (`.tscn` path) and its associated `LayerEntry`.
    *   `SceneSetEntry`: Defines a collection of `SceneEntry` resources that represent a logical game state or screen.
    *   `TransitionEntry`: Defines a transition, linking to a `SceneEntry` that represents the transition animation scene.
*   **Data Location:** These resource instances are typically stored in `data/registry/core/` for framework-level entities and `data/registry/game/` for game-specific entities.

### 2.2. AutoRegistry System

The AutoRegistry system is an editor plugin (`addons/autoregistry/`) that automates the creation of static GDScript classes providing preloaded access to all defined resources.

*   **Functionality:**
    *   Scans predefined directories (configured in `addons/autoregistry/generator.gd` via `REGISTRY_CONFIGS`, e.g., `res://data/registry/core/` and `res://data/registry/game/`).
    *   For each subdirectory (e.g., `events`, `scenes`), it generates a corresponding GDScript class (e.g., `Events.gd`, `Scenes.gd`).
    *   These generated classes contain `const` members for each `.tres` or `.res` file found, preloading the resource. The type of the constant is inferred from the resource's `script_class` or `[gd_resource type="..."]` attribute.
    *   Each generated class also includes a static `ALL` array and a `get_all()` method to easily access all resources of that type.
*   **Generated Output:**
    *   For the "Core" registry configuration (`data/registry/core/`), files are generated in `core/registry/`.
    *   For the "Game" registry configuration (`data/registry/game/`), files are generated in `game/registry/`.
*   **Benefits:**
    *   **Type Safety:** Access resources through typed constants (e.g., `Scenes.MAIN_MENU` instead of `"res://path/to/main_menu.tres"`).
    *   **Discoverability:** Autocompletion for available resources in the script editor.
    *   **Performance:** Resources are preloaded, avoiding runtime `load()` overhead for frequently accessed items.
    *   **Maintainability:** Refactoring resource paths is less error-prone as references are managed by the generator.
*   **Automatic Regeneration:** The plugin monitors the filesystem for changes and automatically regenerates registries with a debounce timer.

### 2.3. Manager Singletons (Autoloads)

A set of singleton managers, configured as autoloads in `project.godot`, provide the core runtime logic for the framework.

*   **`LayerManager` (`core/managers/layer_manager.gd`):**
    *   Responsible for creating and managing `CanvasLayer` nodes.
    *   On `_ready()`, it instantiates `CanvasLayer`s for each `LayerEntry` defined in the `Layers` registry (e.g., `Layers.UI`, `Layers.GAME`).
    *   Provides a `get_layer(layer_entry: LayerEntry)` method to retrieve a specific `CanvasLayer`.

*   **`SceneManager` (`core/managers/scene_manager.gd`):**
    *   Handles the loading, unloading, and tracking of game scenes.
    *   `load_scene(scene_entry: SceneEntry)`: Loads the `.tscn` specified in the `SceneEntry`, instantiates it, and adds it as a child to the `CanvasLayer` defined in the `SceneEntry`'s `layer_entry`.
    *   `unload_scene(scene_entry: SceneEntry)`: Removes and frees the instance of the specified scene.
    *   `get_scene(scene_entry: SceneEntry)`: Retrieves the root node of a loaded scene.
    *   `is_scene_loaded(scene_entry: SceneEntry)`: Checks if a scene is currently loaded.

*   **`EventBus` (`core/managers/event_bus.gd`):**
    *   A global event system for decoupled communication between different parts of the application.
    *   Signals are dynamically created using the `resource_path` of `EventEntry` resources as unique signal names.
    *   `subscribe(event_entry: EventEntry, callable: Callable)`: Connects a callable to an event.
    *   `unsubscribe(event_entry: EventEntry, callable: Callable)`: Disconnects a callable from an event.
    *   `publish(event_entry: EventEntry, data: Dictionary = {})`: Emits an event signal with optional data.
    *   `wait_for(event_entry: EventEntry) -> Dictionary`: Asynchronously waits for an event to be published and returns its data.
    *   **Schema Validation:** If an `EventEntry` defines a `data_schema` (a dictionary of expected keys and their `Variant.Type`), the `EventBus` will validate the payload during `publish`. Errors are reported if the payload doesn't match the schema or if a schema-less event receives data.

*   **`SceneSetManager` (`core/managers/scene_set_manager.gd`):**
    *   Manages collections of scenes, defined by `SceneSetEntry` resources.
    *   `change_set(new_set_entry: SceneSetEntry)`: Transitions from the current scene set to a new one. This process involves:
        1.  Playing an "intro" transition.
        2.  Unloading all scenes from the current set using `SceneManager`.
        3.  Loading all scenes from the new set using `SceneManager`.
        4.  Updating the `_current_set`.
        5.  Playing an "outro" transition.

*   **`TransitionManager` (`core/managers/transition_manager.gd`):**
    *   Manages visual transitions between scene sets.
    *   On `_ready()`, it preloads all scenes defined in `TransitionEntry` resources (via the `Transitions` registry) using `SceneManager`. These scenes are expected to be instances of the `Transition` node.
    *   `set_current_transition(transition_entry: TransitionEntry)`: Sets the active transition animation to be used.
    *   `play_intro()`: Plays the "intro" animation of the current transition.
    *   `play_outro()`: Plays the "outro" animation of the current transition.

### 2.4. Transition System

Reusable screen transitions are implemented using a custom `Transition` node.

*   **`Transition` Node (`core/nodes/transition.gd`):**
    *   A `Control` node designed to host transition animations.
    *   Requires an `AnimationPlayer` child node.
    *   Expects the `AnimationPlayer` to have animations named "intro" and "outro".
    *   The script is marked `@tool` and provides `_get_configuration_warnings()` to display warnings in the editor if the `AnimationPlayer` or required animations are missing.
    *   Manages its own visibility and animation playback.

### 2.5. Core/Game Directory Split

The project structure encourages a separation between the core framework and game-specific logic and assets.

*   **`core/` Directory:**
    *   Contains foundational, game-agnostic code (managers, base node types, core resource definitions).
    *   `core/definitions/`: Scripts for custom resource types used by the framework.
    *   `core/managers/`: Singleton manager scripts.
    *   `core/nodes/`: Reusable custom node scripts (e.g., `Transition`).
    *   `core/registry/`: Autogenerated registry scripts for core resources (e.g., `Layers.gd`, `Events.gd`).
    *   Corresponding data in `data/registry/core/`.

*   **`game/` Directory:**
    *   Intended for all game-specific scenes, scripts, assets, and registry definitions.
    *   `game/registry/`: Autogenerated registry scripts for game-specific resources.
    *   Corresponding data in `data/registry/game/`.

This split helps in keeping the framework reusable and the game logic organized.

## 3. Project Structure Highlights

```
qux/
├── .godot/ # Godot internal project data
├── addons/
│ └── autoregistry/ # AutoRegistry plugin
│ ├── generator.gd
│ ├── plugin.cfg
│ └── plugin.gd
├── core/
│ ├── definitions/ # Scripts for custom Resource types (e.g., SceneEntry.gd)
│ ├── managers/ # Autoloaded manager scripts (e.g., SceneManager.gd)
│ ├── nodes/ # Custom node scripts (e.g., Transition.gd)
│ └── registry/ # AUTOGENERATED registry classes for core resources
├── data/
│ └── registry/
│ ├── core/ # .tres files for core framework (layers, system events)
│ │ ├── events/
│ │ ├── layers/
│ │ ├── scenes/
│ │ ├── scene_sets/
│ │ └── transitions/
│ └── game/ # .tres files for game-specific data (game scenes, game events)
│ └── ...
├── game/
│ ├── main.tscn # Main scene for the game
│ ├── main.gd
│ └── registry/ # AUTOGENERATED registry classes for game resources
├── icon.svg
├── project.godot # Godot project configuration file
└── README.md
```
## 4. Usage

1.  **Define Resources:** Create `.tres` files in the appropriate subdirectories of `data/registry/core/` or `data/registry/game/` (e.g., create `data/registry/game/scenes/level_one.tres` of type `SceneEntry`).
2.  **AutoRegistry Generation:** The AutoRegistry plugin will automatically detect these files and generate/update the corresponding static registry classes (e.g., `GameScenes.LEVEL_ONE` will become available).
3.  **Utilize Managers:**
    *   Load scenes: `SceneManager.load_scene(GameScenes.LEVEL_ONE)`.
    *   Change scene sets: `SceneSetManager.change_set(GameSceneSets.CHAPTER_1)`.
    *   Set active transition: `TransitionManager.set_current_transition(GameTransitions.FADE_TO_BLACK)`.
4.  **Event-Driven Communication:**
    *   Define event types: Create `EventEntry` resources (e.g., `GameEvents.PLAYER_DIED`).
    *   Publish events: `EventBus.publish(GameEvents.PLAYER_DIED, {"score": 100})`.
    *   Subscribe to events: `EventBus.subscribe(GameEvents.PLAYER_DIED, on_player_died)`.
5.  **Develop Game Logic:** Implement game-specific scenes and scripts primarily within the `game/` directory.
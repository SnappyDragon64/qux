# Qux: A Robust Framework Foundation for Godot 4

## Overview

Qux is a foundational framework for Godot 4 projects, designed to promote a highly structured, data-driven, and scalable approach to game development. It is not a game, but a powerful and reusable architecture that provides a suite of robust managers and an automated resource pipeline, allowing you to focus on building your game's logic and content.

The core philosophy is to separate data (defined as Godot `Resource` files) from the logic that operates on it (the singleton `Manager` classes). This creates a clean, maintainable, and designer-friendly workflow.

## Core Philosophy

1.  **Data-Driven by Default:** Scenes, layers, events, and other configurations are defined as `.tres` resource files, not hardcoded. This allows for rapid iteration and modification without changing code.
2.  **Automation over Boilerplate:** The custom **AutoRegistry** plugin automatically scans your data directories and generates static, type-safe script classes to access your resources, eliminating the need for manual `preload()` calls and string paths.
3.  **Decoupled via Managers:** A set of autoloaded (singleton) managers handle core functionalities like scene loading, event communication, and state transitions. This keeps your game code clean and focused on its own responsibilities.
4.  **Clear Separation of Concerns:** The project is organized into a `core` framework and a `game` application layer, making the framework reusable across multiple projects.

---

## Key Features

### 1. The AutoRegistry System

The heart of the framework's workflow is a powerful editor plugin that automates resource management.

*   **How it Works:** The plugin monitors the `data/` directory for changes. When you create, delete, or move a resource file, it automatically regenerates GDScript "registry" classes in the `core/registry/` and `game/registry/` directories.
*   **Static & Type-Safe Access:** Instead of writing `preload("res://data/core/scenes/ui/main_menu.tres")`, you can simply use `Scenes.UI_MAIN_MENU`. This provides compile-time safety and autocompletion in the editor.
*   **Recursive & Organized:** You can organize your resource files into any nested subdirectory structure within the `data/` folders. The generator will create a descriptive constant name from the file's path. For example, a resource at `data/game/levels/world_1/hub.tres` becomes `Levels.WORLD_1_HUB`.
*   **Automatic Updates:** Renaming or moving a file in the Godot editor will trigger the generator to update the registry, so your code references will not break.

### 2. Manager Singletons (Autoloads)

A suite of singleton managers provide the core runtime logic for the framework.

*   **`LayerManager`**: Automatically creates and manages `CanvasLayer` nodes based on `LayerEntry` resources. This provides a structured and data-driven system for render order (e.g., Game, UI, Transitions).

*   **`SceneManager`**: The low-level authority for loading and unloading individual scenes.
    *   **Asynchronous API:** Scene loading is handled via task objects to prevent the game from freezing.
    *   `load_scene(scene_entry: SceneEntry) -> LoadSceneTask`: Initiates loading and returns a `LoadSceneTask` object. To get the result, you `await` the task's `completed` signal: `var scene_node = await task.completed`.
    *   `unload_scene(scene_entry: SceneEntry) -> UnloadSceneTask`: Safely removes and frees a scene instance.
    *   `get_scene(scene_entry: SceneEntry)`: Retrieves the root node of an already-loaded scene.

*   **`SceneSetManager`**: The high-level orchestrator for managing game states. It operates on `SceneSetEntry` resources, which define a group of scenes that should be loaded and active at the same time (e.g., a level and its HUD).
    *   `change_set(new_set: SceneSetEntry)`: This is the primary function for transitioning between game states. It handles the entire sequence: playing an intro transition, unloading all old scenes, loading all new scenes, and finally playing an outro transition.
    *   `reload_current_set()`: A convenient method to unload and reload all scenes in the currently active set.

*   **`TransitionManager`**: Works directly with the `SceneSetManager` to manage visual transitions between scene sets. It operates on `Transition` nodes (custom `Control` nodes with an `AnimationPlayer`) to play "intro" and "outro" animations.

*   **`EventBus`**: A global publish-subscribe system for decoupled communication.
    *   **Schema Validation:** Events can be defined with a `data_schema` in their `EventEntry` resource. The `EventBus` will validate the data payload at runtime, preventing bugs by ensuring the correct data structure is always used.
    *   `publish(event_entry, data)`, `subscribe(event_entry, callable)`, and `wait_for(event_entry)`.

*   **`PauseManager`**: A simple manager to handle the global pause state of the game tree (`get_tree().paused`). It can be enabled or disabled based on the properties of the current `SceneSetEntry`.

---

## The Core Workflow

Here is the typical step-by-step process for using the Qux framework:

1.  **Define Data as Resources:** Create a new resource file in the `data/` directory. For example, create a new `SceneEntry` resource named `main_menu.tres` inside `data/core/scenes/`. Configure its path to your `.tscn` file and assign it a layer.
2.  **Let AutoRegistry Work:** The plugin will automatically detect the new file and add a constant to the corresponding registry. In this case, `core/registry/scenes.gd` will now contain `const MAIN_MENU = preload(...)`.
3.  **Define a Scene Set:** Create a `SceneSetEntry` resource (e.g., `menu_set.tres`) that includes your new `main_menu` scene entry in its array of scenes.
4.  **Use Managers in Code:** From any script (e.g., a startup script in your main scene), call the `SceneSetManager` to load the entire state:
    ```gdscript
    func _ready():
        # The game will now transition to the main menu scene set.
        SceneSetManager.change_set(SceneSets.MENU_SET)
    ```
5.  **Communicate with Events:** To navigate from the menu to the game, publish an event.
    ```gdscript
    # In your main menu button's script
    func _on_play_button_pressed():
        EventBus.publish(Events.START_GAME_REQUESTED)

    # In a game state manager script
    func _ready():
        EventBus.subscribe(Events.START_GAME_REQUESTED, _on_start_game)

    func _on_start_game(data: Dictionary):
        SceneSetManager.change_set(SceneSets.LEVEL_1)
    ```

---

## Project Structure

```
qux/
├── .godot/                # Godot's internal project data
├── addons/
│   └── autoregistry/      # The AutoRegistry editor plugin
├── core/
│   ├── definitions/       # GDScript classes for custom core Resource types (SceneEntry, etc.)
│   ├── managers/          # Autoloaded singleton manager scripts
│   ├── nodes/             # Base scripts for custom node types (e.g., Transition)
│   ├── registry/          # [AUTOGENERATED] Registry classes for core resources
│   └── runtime/           # Helper classes for runtime operations (e.g., LoadSceneTask)
├── data/
│   ├── core/              # .tres files for the core framework (layers, default scenes)
│   └── game/              # .tres files for your specific game (levels, characters, items)
├── game/
│   ├── definitions/       # GDScript classes for custom game Resource types
│   ├── registry/          # [AUTOGENERATED] Registry classes for game resources
│   └── ...                # Your game's scenes, scripts, and assets
└── project.godot          # The main project file defining autoloads
```
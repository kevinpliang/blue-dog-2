# Settings Sound Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a compact settings panel, reachable from the ready and game-over screens, that lets players toggle gameplay sound and tune volume.

**Architecture:** Keep settings ownership in `Main`, alongside the existing HUD and `ConfigFile` persistence. `FeedbackController` exposes a tiny runtime sound-settings interface and remains the only class that decides whether cue audio should play.

**Tech Stack:** Godot 4.5, GDScript, Godot Control UI, `ConfigFile`, existing headless GDScript tests.

---

## Context

Design spec: `docs/superpowers/specs/2026-06-17-settings-sound-panel-design.md`

Use the existing test commands:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_mobile_tap.gd
```

Preflight note: the current `game/main.gd` has `_style_label(_start_title_label, 72)`, while `tests/test_main_smoke.gd` expects the later start-screen `DOG RUN` label to be `44`. Before starting settings work, run the smoke test once. If it fails only on that font-size mismatch, change the line in `game/main.gd` to `_style_label(_start_title_label, 44)`, rerun the smoke test, and commit that baseline fix separately:

```powershell
git add game/main.gd
git commit -m "fix: restore start title font size"
```

## File Structure

- Create `assets/icons/settings.svg`
  - Plain white Material settings glyph only. Rounded-square background stays in Godot UI.
- Modify `game/feedback_controller.gd`
  - Add runtime sound enabled/volume state.
  - Keep `RunnerTuning.audio_enabled` as the global kill switch.
  - Preserve the existing cue mix at volume `1.0`.
- Modify `game/main.gd`
  - Add settings UI controls to the existing HUD CanvasLayer.
  - Persist settings to `user://dog_run.cfg` under `settings/sound_enabled` and `settings/sound_volume`.
  - Apply settings to `FeedbackController`.
  - Block gameplay taps while the modal is open.
- Modify `tests/test_feedback_controller.gd`
  - Verify disabled audio does not assign/play cues.
  - Verify volume scales below the current base cue mix.
- Modify `tests/test_main_smoke.gd`
  - Verify the icon asset is used.
  - Verify settings button visibility by game state.
  - Verify modal opening, tap blocking, and persistence.

---

### Task 1: FeedbackController Sound Settings

**Files:**
- Modify: `tests/test_feedback_controller.gd`
- Modify: `game/feedback_controller.gd`

- [ ] **Step 1: Write the failing feedback-controller test**

Replace `tests/test_feedback_controller.gd` with this complete file:

```gdscript
extends RefCounted

const FeedbackController = preload("res://game/feedback_controller.gd")

var failures: Array[String] = []


func run_all() -> Array[String]:
	var controller = FeedbackController.new()
	controller.prepare()
	expect_equal(controller.particle_pool_size(), FeedbackController.IMPACT_POOL_SIZE, "particle pool is bounded")
	expect_equal(controller.audio_pool_size(), FeedbackController.AUDIO_POOL_SIZE, "audio pool is bounded")
	expect_true(controller.particles_are_idle(), "pooled impact particles start idle")
	controller.handle_events([{"type": "collision"}], Vector3.ZERO)
	expect_true(controller.shake_time > 0.0, "collision starts camera shake")
	controller.free()

	test_sound_settings_gate_and_scale_audio()
	return failures


func test_sound_settings_gate_and_scale_audio() -> void:
	var controller = FeedbackController.new()
	controller.prepare()

	controller.set_sound_settings(false, 1.0)
	controller.handle_events([{"type": "jumped"}], Vector3.ZERO)
	expect_true(controller.first_audio_stream_is_empty(), "disabled sound does not assign a cue stream")

	controller.set_sound_settings(true, 0.5)
	controller.handle_events([{"type": "jumped"}], Vector3.ZERO)
	expect_true(not controller.first_audio_stream_is_empty(), "enabled sound assigns a cue stream")
	expect_true(controller.first_audio_volume_db() < FeedbackController.BASE_AUDIO_VOLUME_DB, "volume below 100 percent lowers cue gain")

	var settings := controller.sound_settings()
	expect_true(bool(settings["enabled"]), "sound settings report enabled")
	expect_true(is_equal_approx(float(settings["volume"]), 0.5), "sound settings report clamped volume")
	controller.free()


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
```

- [ ] **Step 2: Run the focused suite and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_feedback_controller.gd
```

Expected: FAIL because `FeedbackController` does not yet have `set_sound_settings`, `sound_settings`, `first_audio_stream_is_empty`, `first_audio_volume_db`, or `BASE_AUDIO_VOLUME_DB`.

- [ ] **Step 3: Implement runtime sound settings**

In `game/feedback_controller.gd`, replace:

```gdscript
const AUDIO_ENABLED := true
```

with:

```gdscript
const AUDIO_ENABLED := true
const BASE_AUDIO_VOLUME_DB := -8.0
```

After:

```gdscript
var shake_time := 0.0
```

add:

```gdscript
var sound_enabled := true
var sound_volume := 1.0
```

In `prepare()`, replace:

```gdscript
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		_audio_players.append(player)
```

with:

```gdscript
		var player := AudioStreamPlayer.new()
		player.volume_db = _effective_audio_volume_db()
		add_child(player)
		_audio_players.append(player)
```

After `set_feedback_paused(value: bool)`, add:

```gdscript
func set_sound_settings(enabled: bool, volume: float) -> void:
	sound_enabled = enabled
	sound_volume = clampf(volume, 0.0, 1.0)
	for player in _audio_players:
		player.volume_db = _effective_audio_volume_db()


func sound_settings() -> Dictionary:
	return {
		"enabled": sound_enabled,
		"volume": sound_volume,
	}
```

After `audio_pool_size()`, add:

```gdscript
func first_audio_stream_is_empty() -> bool:
	return _audio_players.is_empty() or _audio_players[0].stream == null


func first_audio_volume_db() -> float:
	if _audio_players.is_empty():
		return BASE_AUDIO_VOLUME_DB
	return _audio_players[0].volume_db
```

Replace `_play_cue(type: String)` with:

```gdscript
func _play_cue(type: String) -> void:
	if not TUNING.audio_enabled or not sound_enabled or sound_volume <= 0.0 or _audio_players.is_empty():
		return
	var cue := _audio_library.cue(type)
	if cue == null:
		return
	var player := _audio_players[_audio_index]
	_audio_index = (_audio_index + 1) % _audio_players.size()
	player.volume_db = _effective_audio_volume_db()
	player.stream = cue
	if is_inside_tree():
		player.play()
```

Add this helper above `_vibrate(milliseconds: int)`:

```gdscript
func _effective_audio_volume_db() -> float:
	if sound_volume <= 0.0:
		return -80.0
	return BASE_AUDIO_VOLUME_DB + linear_to_db(sound_volume)
```

- [ ] **Step 4: Run the focused suite and verify GREEN**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_feedback_controller.gd
```

Expected: PASS with no failures.

- [ ] **Step 5: Commit**

```powershell
git add game/feedback_controller.gd tests/test_feedback_controller.gd
git commit -m "feat: add runtime sound settings"
```

---

### Task 2: Main Scene Settings Smoke Coverage

**Files:**
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Add failing smoke-test coverage**

In `tests/test_main_smoke.gd`, after:

```gdscript
	elif not _uses_refreshed_hud():
		push_error("Main scene does not use the refreshed Michroma HUD.")
		quit(1)
```

add:

```gdscript
	elif not _uses_sound_settings_panel():
		push_error("Main scene does not include the sound settings panel.")
		quit(1)
```

Add this helper above `_uses_moderate_lower_third_framing()`:

```gdscript
func _uses_sound_settings_panel() -> bool:
	var settings_save_path := "user://dog_run_settings_smoke.cfg"
	var absolute_path := ProjectSettings.globalize_path(settings_save_path)
	DirAccess.remove_absolute(absolute_path)
	_main._save_path = settings_save_path

	var button: Button = _main.find_child("SettingsButton", true, false)
	var panel: Control = _main.find_child("SettingsPanel", true, false)
	var blocker: Control = _main.find_child("SettingsModalBlocker", true, false)
	var toggle: Button = _main.find_child("SoundToggleButton", true, false)
	var slider: HSlider = _main.find_child("VolumeSlider", true, false)
	var close_button: Button = _main.find_child("CloseSettingsButton", true, false)
	var volume_value: Label = _main.find_child("VolumeValueLabel", true, false)
	if button == null or panel == null or blocker == null or toggle == null or slider == null or close_button == null or volume_value == null:
		DirAccess.remove_absolute(absolute_path)
		return false
	if button.icon == null or button.icon.resource_path != "res://assets/icons/settings.svg":
		DirAccess.remove_absolute(absolute_path)
		return false
	if not is_equal_approx(slider.min_value, 0.0) or not is_equal_approx(slider.max_value, 1.0):
		DirAccess.remove_absolute(absolute_path)
		return false

	_main.simulation.state = _main.simulation.RunState.READY
	_main._update_hud()
	if not button.visible or panel.visible or blocker.visible:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._open_settings()
	if not panel.visible or not blocker.visible:
		DirAccess.remove_absolute(absolute_path)
		return false
	_main._handle_tap()
	if _main.simulation.state != _main.simulation.RunState.READY:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._set_sound_enabled(false)
	_main._set_sound_volume(0.35)
	_main._save_progress()
	_main._set_sound_enabled(true)
	_main._set_sound_volume(1.0)
	_main._load_progress()
	if _main._sound_enabled or not is_equal_approx(_main._sound_volume, 0.35):
		DirAccess.remove_absolute(absolute_path)
		return false
	var feedback_settings: Dictionary = _main._feedback.sound_settings()
	if bool(feedback_settings["enabled"]) or not is_equal_approx(float(feedback_settings["volume"]), 0.35):
		DirAccess.remove_absolute(absolute_path)
		return false
	if toggle.text != "SOUND: OFF" or volume_value.text != "35%":
		DirAccess.remove_absolute(absolute_path)
		return false

	_main._close_settings()
	_main.simulation.start(3456)
	_main._update_hud()
	if button.visible or panel.visible or blocker.visible:
		DirAccess.remove_absolute(absolute_path)
		return false

	_main.simulation.state = _main.simulation.RunState.GAME_OVER
	_main._update_hud()
	var visible_on_game_over := button.visible and not panel.visible and not blocker.visible
	DirAccess.remove_absolute(absolute_path)
	return visible_on_game_over
```

- [ ] **Step 2: Run the smoke test and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: FAIL with `Main scene does not include the sound settings panel.`

- [ ] **Step 3: Commit the failing test only if the team wants red commits**

Default for this repo has often been one commit per completed task. If keeping history green, skip this commit and include this test with Task 3's implementation commit.

---

### Task 3: Settings Icon, Panel UI, Persistence, and Tap Blocking

**Files:**
- Create: `assets/icons/settings.svg`
- Modify: `game/main.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Add the Material settings SVG asset**

Create `assets/icons/settings.svg`:

```xml
<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24" fill="#FFFFFF">
  <path d="m370-80-16-128q-13-5-24.5-12T307-235l-119 50L78-375l103-78q-1-7-1-13.5v-27q0-6.5 1-13.5L78-585l110-190 119 50q11-8 23-15t24-12l16-128h220l16 128q13 5 24.5 12t22.5 15l119-50 110 190-103 78q1 7 1 13.5v27q0 6.5-2 13.5l103 78-110 190-118-50q-11 8-23 15t-24 12L590-80H370Zm70-80h79l14-106q31-8 57.5-23.5T639-327l99 41 39-68-86-65q5-14 7-29.5t2-31.5q0-16-2-31.5t-7-29.5l86-65-39-68-99 42q-22-23-48.5-38.5T533-694l-13-106h-79l-14 106q-31 8-57.5 23.5T321-633l-99-41-39 68 86 64q-5 15-7 30t-2 32q0 16 2 31t7 30l-86 65 39 68 99-42q22 23 48.5 38.5T427-266l13 106Zm42-180q58 0 99-41t41-99q0-58-41-99t-99-41q-59 0-99.5 41T342-480q0 58 40.5 99t99.5 41Zm-2-140Z"/>
</svg>
```

- [ ] **Step 2: Add settings constants and state**

In `game/main.gd`, after:

```gdscript
const HUD_FONT: FontFile = preload("res://assets/fonts/Michroma-Regular.ttf")
```

add:

```gdscript
const SETTINGS_ICON: Texture2D = preload("res://assets/icons/settings.svg")
```

After:

```gdscript
const TRACK_CENTER_Z := -90.0
```

add:

```gdscript
const DEFAULT_SOUND_ENABLED := true
const DEFAULT_SOUND_VOLUME := 1.0
```

After:

```gdscript
var _tutorial_completed := false
```

add:

```gdscript
var _sound_enabled := DEFAULT_SOUND_ENABLED
var _sound_volume := DEFAULT_SOUND_VOLUME
```

After:

```gdscript
var _run_summary_values := {}
```

add:

```gdscript
var _settings_button: Button
var _settings_modal_blocker: ColorRect
var _settings_panel: PanelContainer
var _sound_toggle_button: Button
var _volume_slider: HSlider
var _volume_value_label: Label
```

- [ ] **Step 3: Build settings UI in `_build_hud()`**

In `_build_hud()`, after:

```gdscript
	_run_summary.add_child(restart_label)
```

add:

```gdscript
	_build_settings_ui(root)
```

Add these helper functions after `_add_summary_row(grid: GridContainer, key: String, title_text: String)`:

```gdscript
func _build_settings_ui(root: Control) -> void:
	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_settings_button.offset_left = -88.0
	_settings_button.offset_top = 8.0
	_settings_button.offset_right = -16.0
	_settings_button.offset_bottom = 80.0
	_settings_button.icon = SETTINGS_ICON
	_settings_button.expand_icon = true
	_settings_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_button.focus_mode = Control.FOCUS_NONE
	_settings_button.add_theme_stylebox_override("normal", _make_ui_box_style(Color(0.0, 0.0, 0.0, 0.55), Color(0.0, 0.85, 1.0), 18))
	_settings_button.add_theme_stylebox_override("hover", _make_ui_box_style(Color(0.0, 0.18, 0.22, 0.72), Color(0.0, 0.95, 1.0), 18))
	_settings_button.add_theme_stylebox_override("pressed", _make_ui_box_style(Color(0.0, 0.35, 0.42, 0.85), Color.WHITE, 18))
	_settings_button.pressed.connect(_open_settings)
	root.add_child(_settings_button)

	_settings_modal_blocker = ColorRect.new()
	_settings_modal_blocker.name = "SettingsModalBlocker"
	_settings_modal_blocker.color = Color(0.0, 0.0, 0.0, 0.5)
	_settings_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_modal_blocker.visible = false
	root.add_child(_settings_modal_blocker)

	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.offset_left = -280.0
	_settings_panel.offset_top = -230.0
	_settings_panel.offset_right = 280.0
	_settings_panel.offset_bottom = 230.0
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_panel.visible = false
	_settings_panel.add_theme_stylebox_override("panel", _make_ui_box_style(Color(0.0, 0.02, 0.04, 0.92), Color(0.0, 0.85, 1.0), 28))
	root.add_child(_settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	_settings_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 22)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "SettingsTitleLabel"
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title, 36)
	stack.add_child(title)

	_sound_toggle_button = Button.new()
	_sound_toggle_button.name = "SoundToggleButton"
	_sound_toggle_button.focus_mode = Control.FOCUS_NONE
	_sound_toggle_button.add_theme_font_override("font", _hud_font)
	_sound_toggle_button.add_theme_font_size_override("font_size", 28)
	_sound_toggle_button.add_theme_color_override("font_color", Color.WHITE)
	_sound_toggle_button.add_theme_stylebox_override("normal", _make_ui_box_style(Color(0.0, 0.08, 0.12, 0.75), Color(0.0, 0.85, 1.0), 16))
	_sound_toggle_button.add_theme_stylebox_override("pressed", _make_ui_box_style(Color(0.0, 0.3, 0.35, 0.9), Color.WHITE, 16))
	_sound_toggle_button.pressed.connect(_toggle_sound)
	stack.add_child(_sound_toggle_button)

	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 18)
	stack.add_child(volume_row)

	var volume_label := Label.new()
	volume_label.text = "VOLUME"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(volume_label, 24)
	volume_row.add_child(volume_label)

	_volume_value_label = Label.new()
	_volume_value_label.name = "VolumeValueLabel"
	_volume_value_label.custom_minimum_size = Vector2(100.0, 0.0)
	_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_volume_value_label, 24)
	volume_row.add_child(_volume_value_label)

	_volume_slider = HSlider.new()
	_volume_slider.name = "VolumeSlider"
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.05
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.value_changed.connect(_set_sound_volume)
	stack.add_child(_volume_slider)

	var close_button := Button.new()
	close_button.name = "CloseSettingsButton"
	close_button.text = "CLOSE"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_override("font", _hud_font)
	close_button.add_theme_font_size_override("font_size", 26)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.add_theme_stylebox_override("normal", _make_ui_box_style(Color(0.0, 0.0, 0.0, 0.55), Color(0.0, 0.85, 1.0), 16))
	close_button.add_theme_stylebox_override("pressed", _make_ui_box_style(Color(0.0, 0.3, 0.35, 0.9), Color.WHITE, 16))
	close_button.pressed.connect(_close_settings)
	stack.add_child(close_button)

	_sync_settings_controls()
```

Add this style helper after `_style_label(label: Label, font_size: int)`:

```gdscript
func _make_ui_box_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
```

- [ ] **Step 4: Add settings control methods**

Add these methods after `_handle_tap()`:

```gdscript
func _open_settings() -> void:
	if _settings_panel == null or _settings_modal_blocker == null:
		return
	if simulation.state != Simulation.RunState.READY and simulation.state != Simulation.RunState.GAME_OVER:
		return
	_sync_settings_controls()
	_settings_modal_blocker.visible = true
	_settings_panel.visible = true


func _close_settings() -> void:
	if _settings_panel != null:
		_settings_panel.visible = false
	if _settings_modal_blocker != null:
		_settings_modal_blocker.visible = false


func _settings_open() -> bool:
	return _settings_panel != null and _settings_panel.visible


func _toggle_sound() -> void:
	_set_sound_enabled(not _sound_enabled)


func _set_sound_enabled(value: bool) -> void:
	_sound_enabled = value
	_apply_sound_settings()
	_sync_settings_controls()
	_save_progress()


func _set_sound_volume(value: float) -> void:
	_sound_volume = clampf(value, 0.0, 1.0)
	_apply_sound_settings()
	_sync_settings_controls()
	_save_progress()


func _apply_sound_settings() -> void:
	if _feedback != null:
		_feedback.set_sound_settings(_sound_enabled, _sound_volume)


func _sync_settings_controls() -> void:
	if _sound_toggle_button != null:
		_sound_toggle_button.text = "SOUND: ON" if _sound_enabled else "SOUND: OFF"
	if _volume_slider != null and not is_equal_approx(_volume_slider.value, _sound_volume):
		_volume_slider.set_value_no_signal(_sound_volume)
	if _volume_value_label != null:
		_volume_value_label.text = "%d%%" % roundi(_sound_volume * 100.0)
```

- [ ] **Step 5: Route taps safely around settings**

At the start of `_handle_pointer_release(end_position: Vector2)`, add:

```gdscript
	if _settings_open():
		return
	if _settings_button != null and _settings_button.visible and _settings_button.get_global_rect().has_point(end_position):
		_open_settings()
		return
```

At the start of `_handle_tap()`, add:

```gdscript
	if _settings_open():
		return
```

This second guard is intentionally redundant because tests and keyboard input can call `_handle_tap()` directly.

- [ ] **Step 6: Update HUD visibility**

In `_update_hud()`, after:

```gdscript
	_start_title_label.visible = false
```

add:

```gdscript
	if _settings_button != null:
		_settings_button.visible = simulation.state == Simulation.RunState.READY or simulation.state == Simulation.RunState.GAME_OVER
	if simulation.state != Simulation.RunState.READY and simulation.state != Simulation.RunState.GAME_OVER:
		_close_settings()
```

- [ ] **Step 7: Persist sound settings**

Replace `_save_progress()` with:

```gdscript
func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.set_value("progress", "tutorial_completed", _tutorial_completed)
	config.set_value("settings", "sound_enabled", _sound_enabled)
	config.set_value("settings", "sound_volume", _sound_volume)
	config.save(_save_path)
```

Replace `_load_progress()` with:

```gdscript
func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(_save_path) == OK:
		high_score = int(config.get_value("scores", "high_score", 0))
		_tutorial_completed = bool(config.get_value("progress", "tutorial_completed", false))
		_sound_enabled = bool(config.get_value("settings", "sound_enabled", DEFAULT_SOUND_ENABLED))
		_sound_volume = clampf(float(config.get_value("settings", "sound_volume", DEFAULT_SOUND_VOLUME)), 0.0, 1.0)
	_apply_sound_settings()
	_sync_settings_controls()
```

- [ ] **Step 8: Run the smoke test and verify GREEN**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: `Dog Run active scene smoke test passed.`

- [ ] **Step 9: Run mobile tap regression**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_mobile_tap.gd
```

Expected: `Dog Run mobile tap test passed.`

- [ ] **Step 10: Commit**

```powershell
git add assets/icons/settings.svg game/main.gd tests/test_main_smoke.gd
git commit -m "feat: add sound settings panel"
```

---

### Task 4: Full Verification and Export Sanity

**Files:**
- Verify: `game/main.gd`
- Verify: `game/feedback_controller.gd`
- Verify: `assets/icons/settings.svg`
- Verify: `tests/test_feedback_controller.gd`
- Verify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Run the full simulation suite**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
```

Expected:

```text
Dog Run simulation tests passed.
```

- [ ] **Step 2: Run scene and tap smoke tests**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_mobile_tap.gd
```

Expected:

```text
Dog Run active scene smoke test passed.
Dog Run mobile tap test passed.
```

- [ ] **Step 3: Inspect the changed files**

Run:

```powershell
git diff --stat HEAD
git diff -- game/main.gd game/feedback_controller.gd tests/test_feedback_controller.gd tests/test_main_smoke.gd assets/icons/settings.svg
```

Expected:

- Only the settings icon, settings UI, audio settings, and tests are changed.
- No gameplay tuning values are changed.
- No export preset or platform build settings are changed.

- [ ] **Step 4: Commit any final verification-only adjustments**

Only run this if Step 3 revealed a tiny required correction, such as a typo in a control name or expected label text:

```powershell
git add assets/icons/settings.svg game/main.gd game/feedback_controller.gd tests/test_feedback_controller.gd tests/test_main_smoke.gd
git commit -m "fix: polish sound settings panel"
```

If Step 3 showed no changes after Task 3, do not create an empty commit.

---

## Self-Review

**Spec coverage**

- Rounded-square top-right settings button: Task 3, Steps 1-3.
- Button hidden during active gameplay: Task 3, Step 6 and Task 2 smoke helper.
- Checked-in Material settings SVG: Task 3, Step 1 and Task 2 smoke helper.
- Centered modal panel with `SETTINGS`, `SOUND`, `VOLUME`, and `CLOSE`: Task 3, Step 3.
- Modal blocks taps behind it: Task 3, Step 5 and Task 2 smoke helper.
- Michroma white/cyan styling: Task 3, Step 3.
- Default sound ON and volume 100%: Task 3, Step 2.
- 100% preserves current mix; lower volume scales down: Task 1, Steps 3-4.
- Sound OFF prevents gameplay cues: Task 1, Steps 1-4.
- Persistence in `user://dog_run.cfg`: Task 3, Step 7 and Task 2 smoke helper.
- Existing saves default to ON/1.0: Task 3, Step 7.

**Placeholder scan**

This plan contains no deferred implementation placeholders and no references to undefined methods after all tasks are applied.

**Type consistency**

- `Main._sound_enabled` and `FeedbackController.sound_enabled` are both `bool`.
- `Main._sound_volume` and `FeedbackController.sound_volume` are both clamped `float` values in `[0.0, 1.0]`.
- The smoke test references `SettingsButton`, `SettingsModalBlocker`, `SettingsPanel`, `SoundToggleButton`, `VolumeSlider`, `VolumeValueLabel`, and `CloseSettingsButton`, all created in Task 3.
- The smoke test calls `_open_settings`, `_close_settings`, `_set_sound_enabled`, `_set_sound_volume`, `_save_progress`, and `_load_progress`, all present after Task 3.

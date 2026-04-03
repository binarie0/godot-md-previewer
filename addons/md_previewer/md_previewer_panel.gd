@tool
extends Control

## Markdown Previewer Panel
## Manages multiple MD file tabs and renders them as BBCode in RichTextLabel.

const EMPTY_LABEL := "[color=#4a5568][i]No file open. Click  Open File  to load a .md file.[/i][/color]"

var tab_container: TabContainer
var toolbar: HBoxContainer
var open_btn: Button
var close_btn: Button
var reload_btn: Button
var file_label: Label
var file_dialog: FileDialog

# Maps tab index -> { path, mtime }
var tab_data: Array[Dictionary] = []

# Auto-reload timer
var reload_timer: float = 0.0
var RELOAD_INTERVAL: float = 2.0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(0, 200)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Toolbar
	toolbar = HBoxContainer.new()
	toolbar.custom_minimum_size.y = 32
	vbox.add_child(toolbar)

	open_btn = _make_button("📂 Open File", Color(0.42, 0.62, 0.87))
	open_btn.pressed.connect(_on_open_pressed)
	toolbar.add_child(open_btn)

	reload_btn = _make_button("🔄 Reload", Color(0.56, 0.82, 0.64))
	reload_btn.pressed.connect(_on_reload_pressed)
	reload_btn.disabled = true
	toolbar.add_child(reload_btn)

	close_btn = _make_button("✕ Close Tab", Color(0.95, 0.54, 0.54))
	close_btn.pressed.connect(_on_close_pressed)
	close_btn.disabled = true
	toolbar.add_child(close_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	file_label = Label.new()
	file_label.text = "No file open"
	file_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	file_label.add_theme_font_size_override("font_size", 11)
	file_label.clip_text = true
	file_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(file_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Tab Container
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.tab_changed.connect(_on_tab_changed)
	vbox.add_child(tab_container)

	_add_empty_tab()


func _make_button(label: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_color_override("font_color", color)
	btn.custom_minimum_size = Vector2(120, 26)
	return btn


func _make_preview_rtl() -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = false
	rtl.scroll_active = true
	rtl.scroll_following = false
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.add_theme_font_size_override("normal_font_size", 14)
	rtl.add_theme_color_override("default_color", Color(0.88, 0.88, 0.88))
	return rtl


func _add_empty_tab() -> void:
	if tab_container.tab_changed.is_connected(_on_tab_changed):
		tab_container.tab_changed.disconnect(_on_tab_changed)
	var rtl := _make_preview_rtl()
	tab_container.add_child(rtl)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, "Welcome")
	tab_data.append({ "path": "", "mtime": 0 })
	rtl.parse_bbcode(EMPTY_LABEL)
	if not tab_container.tab_changed.is_connected(_on_tab_changed):
		tab_container.tab_changed.connect(_on_tab_changed)


func _load_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("MDPreviewer: File not found: " + path)
		return

	# Check if already open in a tab
	for i in tab_data.size():
		if tab_data[i].path == path:
			tab_container.current_tab = i
			return

	var fa := FileAccess.open(path, FileAccess.READ)
	var md_text := fa.get_as_text()
	fa.close()
	var bbcode := MarkdownParser.parse(md_text)

	# Find first empty tab
	var empty_idx := -1
	for i in tab_data.size():
		if (tab_data[i].path as String) == "":
			empty_idx = i
			break

	if empty_idx >= 0:
		var rtl := tab_container.get_child(empty_idx) as RichTextLabel
		rtl.parse_bbcode(bbcode)
		tab_data[empty_idx] = { "path": path, "mtime": _get_mtime(path) }
		tab_container.set_tab_title(empty_idx, path.get_file())
		tab_container.current_tab = empty_idx
	else:
		if tab_container.tab_changed.is_connected(_on_tab_changed):
			tab_container.tab_changed.disconnect(_on_tab_changed)
		var rtl := _make_preview_rtl()
		tab_container.add_child(rtl)
		var new_idx := tab_container.get_tab_count() - 1
		tab_container.set_tab_title(new_idx, path.get_file())
		tab_data.append({ "path": path, "mtime": _get_mtime(path) })
		rtl.parse_bbcode(bbcode)
		if not tab_container.tab_changed.is_connected(_on_tab_changed):
			tab_container.tab_changed.connect(_on_tab_changed)
		tab_container.current_tab = new_idx

	_refresh_toolbar()


func _reload_current() -> void:
	var idx := tab_container.current_tab
	if idx < 0 or idx >= tab_data.size():
		return
	var path: String = tab_data[idx].path
	if path == "" or not FileAccess.file_exists(path):
		return
	var fa := FileAccess.open(path, FileAccess.READ)
	var md_text := fa.get_as_text()
	fa.close()
	var bbcode := MarkdownParser.parse(md_text)
	var rtl := tab_container.get_child(idx) as RichTextLabel
	rtl.parse_bbcode(bbcode)
	tab_data[idx].mtime = _get_mtime(path)


func _get_mtime(path: String) -> int:
	return FileAccess.get_modified_time(path)


func _refresh_toolbar() -> void:
	if tab_container == null or tab_data == null:
		return
	var idx := tab_container.current_tab
	if idx < 0 or idx >= tab_data.size():
		reload_btn.disabled = true
		close_btn.disabled = true
		file_label.text = "No file open"
		return
	var has_file: bool = (tab_data[idx].path as String) != ""
	reload_btn.disabled = not has_file
	close_btn.disabled = false
	if has_file:
		file_label.text = tab_data[idx].path as String
	else:
		file_label.text = "No file open"


# Signal Handlers

func _on_open_pressed() -> void:
	if file_dialog == null:
		file_dialog = FileDialog.new()
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = ["*.md ; Markdown Files", "*.markdown ; Markdown Files"]
		file_dialog.file_selected.connect(_on_file_selected)
		add_child(file_dialog)
	file_dialog.popup_centered(Vector2(800, 600))


func _on_file_selected(path: String) -> void:
	_load_file(path)


func _on_reload_pressed() -> void:
	_reload_current()


func _on_close_pressed() -> void:
	var idx := tab_container.current_tab
	_close_tab(idx)


func _on_tab_close_pressed(tab_idx: int) -> void:
	_close_tab(tab_idx)


func _on_tab_changed(_tab: int) -> void:
	if tab_data == null or tab_data.size() == 0:
		return
	_refresh_toolbar()


func _close_tab(idx: int) -> void:
	if idx < 0 or idx >= tab_container.get_tab_count():
		return
	if tab_container.tab_changed.is_connected(_on_tab_changed):
		tab_container.tab_changed.disconnect(_on_tab_changed)
	var child := tab_container.get_child(idx)
	tab_container.remove_child(child)
	child.queue_free()
	tab_data.remove_at(idx)
	if not tab_container.tab_changed.is_connected(_on_tab_changed):
		tab_container.tab_changed.connect(_on_tab_changed)
	if tab_container.get_tab_count() == 0:
		_add_empty_tab()
	_refresh_toolbar()


# Auto-reload

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	reload_timer += delta
	if reload_timer < RELOAD_INTERVAL:
		return
	reload_timer = 0.0

	for i in tab_data.size():
		var path: String = tab_data[i].path
		if path == "" or not FileAccess.file_exists(path):
			continue
		var mtime := _get_mtime(path)
		if mtime != tab_data[i].mtime:
			var fa := FileAccess.open(path, FileAccess.READ)
			var md_text := fa.get_as_text()
			fa.close()
			var bbcode := MarkdownParser.parse(md_text)
			var rtl := tab_container.get_child(i) as RichTextLabel
			rtl.parse_bbcode(bbcode)
			tab_data[i].mtime = mtime

extends Control
class_name SaveSlotScreen

signal save_requested(slot: int)
signal cancel_requested

var _slots_container: VBoxContainer
var _occupied_slots: Array[int] = []
var _pending_slot: int = -1
var _confirmation: ConfirmationDialog


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "SaveSlotPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520.0, 420.0)
	add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "SaveSlotLayout"
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = Localization.text("ui.salvar_campanha")
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	_slots_container = VBoxContainer.new()
	_slots_container.name = "SaveSlots"
	_slots_container.add_theme_constant_override("separation", 8)
	layout.add_child(_slots_container)
	var cancel_button: Button = Button.new()
	cancel_button.text = Localization.text("ui.cancelar")
	cancel_button.custom_minimum_size = Vector2(0.0, 44.0)
	cancel_button.focus_mode = Control.FOCUS_ALL
	cancel_button.pressed.connect(func() -> void: cancel_requested.emit())
	cancel_button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
	layout.add_child(cancel_button)
	_confirmation = ConfirmationDialog.new()
	_confirmation.dialog_text = Localization.text("ui.sobrescrever_save")
	_confirmation.ok_button_text = Localization.text("ui.confirmar")
	_confirmation.cancel_button_text = Localization.text("ui.cancelar")
	_confirmation.confirmed.connect(_on_overwrite_confirmed)
	add_child(_confirmation)


func open_slots(occupied_slots: Array[int]) -> void:
	_occupied_slots = occupied_slots.duplicate()
	for child: Node in _slots_container.get_children():
		_slots_container.remove_child(child)
		child.queue_free()
	for slot: int in range(DataManager.SAVE_SLOT_COUNT):
		var button: Button = Button.new()
		button.name = "SaveSlot_%d" % slot
		button.text = Localization.format(
			"ui.save_slot_format",
			{
				"slot": slot + 1,
				"state": (
					Localization.text("ui.slot_ocupado")
					if _occupied_slots.has(slot)
					else Localization.text("ui.slot_vazio")
				)
			}
		)
		button.custom_minimum_size = Vector2(0.0, 48.0)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_slot_pressed.bind(slot))
		button.pressed.connect(func() -> void: EventBus.ui_audio_requested.emit("ui_confirm"))
		_slots_container.add_child(button)
	visible = true
	if _slots_container.get_child_count() > 0:
		(_slots_container.get_child(0) as Button).grab_focus()


func _on_slot_pressed(slot: int) -> void:
	if _occupied_slots.has(slot):
		_pending_slot = slot
		_confirmation.popup_centered()
		return
	save_requested.emit(slot)


func _on_overwrite_confirmed() -> void:
	if _pending_slot < 0 or _pending_slot >= DataManager.SAVE_SLOT_COUNT:
		push_error("Cannot overwrite save because the selected slot is invalid.")
		return
	save_requested.emit(_pending_slot)
	_pending_slot = -1

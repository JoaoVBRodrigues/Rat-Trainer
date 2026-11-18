extends Node

const OUT: String = "res://design/assets/reviews/visual-art-pass/2026-11-18/"
var phase: String = "before"

func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg in ["before", "after"]:
			phase = arg
	call_deferred("run")

func shot(label: String) -> void:
	for frame: int in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = OUT + phase + "/" + label + ".png"
	var result: Error = get_viewport().get_texture().get_image().save_png(path)
	assert(result == OK)
	print("CAPTURE ", path)

func run() -> void:
	get_tree().root.size = Vector2i(1024, 768)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + phase))
	var sim: SimulationCore = SimulationCore.new()
	assert(sim.initialize())
	var screen: MainScreen = MainScreen.new()
	add_child(screen)
	screen.update_simulation(sim, {"name": "Nyx Volt", "guardian_name": "ORAC"})
	await shot("main_screen")
	var status: StatusPanel = screen.find_child("StatusPanel", true, false) as StatusPanel
	status.set_expanded(true)
	await shot("status_screen")
	status.set_expanded(false)
	var items: ItemManagementScreen = screen.find_child("ItemManagementScreen", true, false) as ItemManagementScreen
	items.open("shops", sim)
	await shot("items_screen")
	items.visible = false
	var encounter: EncounterScreen = EncounterScreen.new()
	screen.add_child(encounter)
	encounter.open_encounter("rastreador", "Rastreador")
	await shot("mission_screen")
	encounter.visible = false
	var gallery: EndingGallery = EndingGallery.new()
	screen.add_child(gallery)
	var ids: Array[String] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/endings.json"))
	for ending: Dictionary in data["endings"]:
		ids.append(str(ending["id"]))
	gallery.open_gallery(ids, [])
	await shot("endings_screen")
	print("RUNTIME_RESOLUTION ", get_node("/root/Assets").get_debug_report())
	var measurements: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "measurements.json"))
	var resolutions: Array[Dictionary] = []
	var resolver: AssetResolver = get_node("/root/Assets") as AssetResolver
	for entry: Dictionary in measurements["coverage"]:
		var texture: Texture2D = resolver.get_texture(StringName(entry["id"]), StringName(entry["category"]))
		var key: String = str(entry["category"]) + "/" + str(entry["id"])
		resolutions.append({"key": key, "source": resolver.get("_resolution_by_asset").get(key), "path": texture.resource_path, "width": texture.get_width(), "height": texture.get_height()})
	var evidence: FileAccess = FileAccess.open(OUT + phase + "/resolution.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify(resolutions, "\t"))
	evidence.close()
	print("EXHAUSTIVE_RESOLUTION ", resolver.get_debug_report())
	screen.queue_free()
	await get_tree().process_frame
	get_tree().quit()

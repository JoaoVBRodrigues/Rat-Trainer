extends SceneTree

func _initialize() -> void:
	var result: Dictionary = {}
	for category: String in ["backgrounds", "characters", "icons"]:
		var directory: String = "res://assets/art/" + category
		for filename: String in DirAccess.get_files_at(directory):
			if not filename.ends_with(".png"):
				continue
			var path: String = directory + "/" + filename
			var data: PackedByteArray = FileAccess.get_file_as_bytes(path)
			if data.slice(0, 4).get_string_from_ascii() != "RIFF":
				continue
			var image: Image = Image.new()
			var error: Error = image.load_webp_from_buffer(data)
			assert(error == OK)
			var transparent: int = 0
			var partial: int = 0
			var alpha_min: float = 1.0
			var alpha_max: float = 0.0
			for y: int in range(image.get_height()):
				for x: int in range(image.get_width()):
					var alpha: float = image.get_pixel(x, y).a
					alpha_min = minf(alpha_min, alpha)
					alpha_max = maxf(alpha_max, alpha)
					if alpha == 0.0:
						transparent += 1
					elif alpha < 1.0:
						partial += 1
			result[path.trim_prefix("res://")] = {"width": image.get_width(), "height": image.get_height(), "alpha_min": roundi(alpha_min * 255), "alpha_max": roundi(alpha_max * 255), "zero": transparent, "partial": partial}
	var file: FileAccess = FileAccess.open("res://design/assets/reviews/visual-art-pass/2026-11-18/webp_metadata.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	quit()

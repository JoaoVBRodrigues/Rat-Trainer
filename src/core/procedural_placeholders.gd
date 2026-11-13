class_name ProceduralPlaceholders
extends RefCounted

const PLACEHOLDER_DEFINITIONS: Array[Dictionary] = [
	{"id": "ui_panel", "category": "ui", "size": Vector2i(256, 64)},
	{"id": "char_rat_idle", "category": "characters", "size": Vector2i(96, 128)},
	{"id": "bg_bedroom_day", "category": "backgrounds", "size": Vector2i(256, 192)},
	{"id": "icon_stat_str", "category": "icons", "size": Vector2i(48, 48)},
	{"id": "item_generic", "category": "items", "size": Vector2i(48, 48)},
	{"id": "monster_generic", "category": "monsters", "size": Vector2i(64, 64)}
]

const FONT_3X5: Dictionary = {
	"A": ["010", "101", "111", "101", "101"],
	"B": ["110", "101", "110", "101", "110"],
	"C": ["011", "100", "100", "100", "011"],
	"D": ["110", "101", "101", "101", "110"],
	"E": ["111", "100", "110", "100", "111"],
	"F": ["111", "100", "110", "100", "100"],
	"G": ["011", "100", "101", "101", "011"],
	"H": ["101", "101", "111", "101", "101"],
	"I": ["111", "010", "010", "010", "111"],
	"J": ["001", "001", "001", "101", "010"],
	"K": ["101", "101", "110", "101", "101"],
	"L": ["100", "100", "100", "100", "111"],
	"M": ["101", "111", "111", "101", "101"],
	"N": ["101", "111", "111", "111", "101"],
	"O": ["010", "101", "101", "101", "010"],
	"P": ["110", "101", "110", "100", "100"],
	"Q": ["010", "101", "101", "111", "011"],
	"R": ["110", "101", "110", "101", "101"],
	"S": ["011", "100", "010", "001", "110"],
	"T": ["111", "010", "010", "010", "010"],
	"U": ["101", "101", "101", "101", "111"],
	"V": ["101", "101", "101", "101", "010"],
	"W": ["101", "101", "111", "111", "101"],
	"X": ["101", "101", "010", "101", "101"],
	"Y": ["101", "101", "010", "010", "010"],
	"Z": ["111", "001", "010", "100", "111"],
	"0": ["111", "101", "101", "101", "111"],
	"1": ["010", "110", "010", "010", "111"],
	"2": ["110", "001", "010", "100", "111"],
	"3": ["110", "001", "010", "001", "110"],
	"4": ["101", "101", "111", "001", "001"],
	"5": ["111", "100", "110", "001", "110"],
	"6": ["011", "100", "110", "101", "010"],
	"7": ["111", "001", "010", "010", "010"],
	"8": ["010", "101", "010", "101", "010"],
	"9": ["010", "101", "011", "001", "110"],
	"_": ["000", "000", "000", "000", "111"],
	" ": ["000", "000", "000", "000", "000"],
	"?": ["110", "001", "010", "000", "010"]
}


static func generate_all(output_root: String = "res://assets/placeholders") -> Array[String]:
	var created: Array[String] = []
	for definition: Dictionary in PLACEHOLDER_DEFINITIONS:
		var category: String = str(definition["category"])
		var asset_id: String = str(definition["id"])
		var size_value: Variant = definition.get("size")
		if not size_value is Vector2i:
			push_error("Placeholder definition '%s' has no valid Vector2i size." % asset_id)
			continue
		var size: Vector2i = size_value
		var category_path: String = output_root.path_join(category)
		var absolute_category_path: String = ProjectSettings.globalize_path(category_path)
		var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_category_path)
		if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
			push_error(
				"Could not create placeholder directory '%s': %s."
				% [category_path, error_string(directory_error)]
			)
			continue

		var image: Image = _create_image(asset_id, category, size)
		var output_path: String = category_path.path_join("%s.png" % asset_id)
		var save_error: Error = image.save_png(ProjectSettings.globalize_path(output_path))
		if save_error != OK:
			push_error("Could not save placeholder '%s': %s." % [output_path, error_string(save_error)])
			continue
		created.append(output_path)
	return created


static func create_texture(asset_id: String, category: String) -> ImageTexture:
	var image: Image = _create_image(asset_id, category, _size_for_category(category))
	return ImageTexture.create_from_image(image)


static func _create_image(asset_id: String, category: String, size: Vector2i) -> Image:
	var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var base_color: Color = _base_color_for_category(category)
	var accent_color: Color = _accent_color_for_category(category)
	image.fill(base_color)

	_draw_category_shape(image, category, accent_color)
	_draw_border(image, accent_color)
	_draw_id(image, asset_id)
	return image


static func _draw_category_shape(image: Image, category: String, accent: Color) -> void:
	match category:
		"ui":
			_fill_rect(image, Rect2i(8, 8, image.get_width() - 16, 12), accent.darkened(0.25))
			_fill_rect(image, Rect2i(12, 30, image.get_width() - 24, 4), accent)
			_fill_rect(image, Rect2i(12, 42, image.get_width() - 56, 4), accent.darkened(0.25))
		"backgrounds":
			var width: int = image.get_width()
			var height: int = image.get_height()
			_fill_rect(image, Rect2i(8, 12, 92, 82), Color(0.12, 0.16, 0.29))
			_fill_rect(image, Rect2i(14, 18, 80, 68), Color(0.45, 0.72, 0.79))
			_fill_rect(image, Rect2i(50, 18, 6, 68), accent)
			_fill_rect(image, Rect2i(14, 46, 80, 6), accent)
			_fill_rect(image, Rect2i(0, height - 42, width, 42), Color(0.19, 0.14, 0.27))
			_fill_rect(image, Rect2i(126, height - 78, 118, 36), Color(0.34, 0.2, 0.33))
			_fill_rect(image, Rect2i(136, height - 96, 76, 18), accent.darkened(0.2))
			for x: int in range(108, width, 24):
				_fill_rect(image, Rect2i(x, 24 + (x % 3) * 8, 3, 3), Color(0.9, 0.75, 0.49))
		"characters":
			_fill_rect(image, Rect2i(24, 12, 20, 22), Color(0.72, 0.38, 0.45))
			_fill_rect(image, Rect2i(52, 12, 20, 22), Color(0.72, 0.38, 0.45))
			_fill_rect(image, Rect2i(22, 24, 52, 42), Color(0.69, 0.54, 0.49))
			_fill_rect(image, Rect2i(18, 65, 60, 42), Color(0.29, 0.37, 0.55))
			_fill_rect(image, Rect2i(27, 38, 5, 5), Color(0.1, 0.08, 0.12))
			_fill_rect(image, Rect2i(63, 38, 5, 5), Color(0.1, 0.08, 0.12))
			_fill_rect(image, Rect2i(73, 82, 16, 4), Color(0.69, 0.54, 0.49))
			_fill_rect(image, Rect2i(85, 78, 4, 4), Color(0.69, 0.54, 0.49))
			_fill_rect(image, Rect2i(28, 104, 16, 18), Color(0.2, 0.18, 0.24))
			_fill_rect(image, Rect2i(52, 104, 16, 18), Color(0.2, 0.18, 0.24))
		"icons":
			_fill_rect(image, Rect2i(20, 7, 8, 34), accent)
			_fill_rect(image, Rect2i(7, 20, 34, 8), accent)
		"items":
			_fill_rect(image, Rect2i(12, 12, 24, 26), Color(0.72, 0.44, 0.21))
			_fill_rect(image, Rect2i(17, 7, 14, 7), accent)
			_fill_rect(image, Rect2i(17, 22, 14, 5), Color(0.93, 0.75, 0.38))
		"monsters":
			_fill_rect(image, Rect2i(14, 12, 36, 36), Color(0.56, 0.2, 0.3))
			_fill_rect(image, Rect2i(8, 18, 8, 16), accent)
			_fill_rect(image, Rect2i(48, 18, 8, 16), accent)
			_fill_rect(image, Rect2i(22, 24, 5, 5), Color(1.0, 0.85, 0.42))
			_fill_rect(image, Rect2i(37, 24, 5, 5), Color(1.0, 0.85, 0.42))
		_:
			_fill_rect(image, Rect2i(8, 8, image.get_width() - 16, image.get_height() - 16), accent.darkened(0.35))


static func _draw_border(image: Image, accent: Color) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	for x: int in range(width):
		image.set_pixel(x, 0, accent)
		image.set_pixel(x, height - 1, accent)
	for y: int in range(height):
		image.set_pixel(0, y, accent)
		image.set_pixel(width - 1, y, accent)


static func _draw_id(image: Image, asset_id: String) -> void:
	var label: String = asset_id.to_upper().replace("_", " ")
	var maximum_characters: int = max(1, int((image.get_width() - 6) / 4))
	if label.length() > maximum_characters:
		label = label.substr(0, maximum_characters)
	var label_width: int = label.length() * 4 - 1
	var start_x: int = max(2, int((image.get_width() - label_width) / 2))
	var start_y: int = image.get_height() - 8
	if start_y < 1:
		return

	for character_index: int in range(label.length()):
		var character: String = label.substr(character_index, 1)
		var glyph: Array = FONT_3X5.get(character, FONT_3X5["?"])
		for row: int in range(glyph.size()):
			var bits: String = str(glyph[row])
			for column: int in range(bits.length()):
				if bits.substr(column, 1) == "1":
					var pixel_x: int = start_x + character_index * 4 + column
					var pixel_y: int = start_y + row
					if pixel_y < image.get_height() - 1:
						image.set_pixel(pixel_x, pixel_y, Color(1.0, 0.92, 0.73))


static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)


static func _size_for_category(category: String) -> Vector2i:
	match category:
		"ui":
			return Vector2i(128, 64)
		"characters":
			return Vector2i(96, 128)
		"backgrounds":
			return Vector2i(256, 192)
		"icons", "items", "fx":
			return Vector2i(48, 48)
		"monsters":
			return Vector2i(64, 64)
		_:
			return Vector2i(96, 64)


static func _base_color_for_category(category: String) -> Color:
	match category:
		"ui":
			return Color(0.07, 0.1, 0.18)
		"characters":
			return Color(0.17, 0.12, 0.2, 0.0)
		"backgrounds":
			return Color(0.12, 0.11, 0.23)
		"icons":
			return Color(0.12, 0.19, 0.18)
		"items":
			return Color(0.2, 0.15, 0.08)
		"monsters":
			return Color(0.2, 0.08, 0.11)
		_:
			return Color(0.15, 0.15, 0.18)


static func _accent_color_for_category(category: String) -> Color:
	match category:
		"ui":
			return Color(0.37, 0.78, 0.84)
		"characters":
			return Color(0.88, 0.54, 0.66)
		"backgrounds":
			return Color(0.93, 0.65, 0.43)
		"icons":
			return Color(0.55, 0.87, 0.67)
		"items":
			return Color(0.93, 0.75, 0.38)
		"monsters":
			return Color(0.94, 0.4, 0.4)
		_:
			return Color(0.75, 0.75, 0.82)
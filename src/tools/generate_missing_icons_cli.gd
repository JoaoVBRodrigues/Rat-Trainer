extends SceneTree

# Generates missing placeholder icons for UI

static func generate_missing_icons() -> void:
    var icons_to_create: Array = [
        "icon_agenda",
        "icon_profile",
        "icon_city",
        "icon_equipment",
        "icon_talk",
        "icon_mission"
    ]

    var output_dir: String = "res://assets/placeholders/icons"
    var dir: DirAccess = DirAccess.open(output_dir)
    if dir == null:
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
        dir = DirAccess.open(output_dir)

    for icon_id in icons_to_create:
        var path: String = output_dir.path_join(icon_id + ".png")
        if not FileAccess.file_exists(path):
            var image: Image = _create_icon_image(icon_id)
            image.save_png(ProjectSettings.globalize_path(path))
            print("Created: ", path)


static func _create_icon_image(icon_id: String) -> Image:
    var size: Vector2i = Vector2i(48, 48)
    var image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)

    # Base color based on icon ID
    var colors: Dictionary = {
        "agenda": Color(0.37, 0.78, 0.84),
        "profile": Color(0.88, 0.54, 0.66),
        "city": Color(0.53, 0.78, 0.91),
        "equipment": Color(0.93, 0.65, 0.43),
        "talk": Color(0.75, 0.82, 0.91),
        "mission": Color(0.45, 0.85, 0.45),
        "rest": Color(0.68, 0.85, 0.58),
        "options": Color(0.94, 0.4, 0.4),
        "schedule": Color(0.85, 0.44, 0.21)
    }

    var base_color: Color = colors.get(icon_id.trim_prefix("icon_"), Color(0.75, 0.75, 0.82))
    image.fill(base_color)

    # Draw icon shape based on ID
    var accent: Color = Color(1.0, 0.92, 0.73)
    match icon_id:
        "agenda":
            image.fill_rect(Rect2i(8, 8, 32, 32), base_color)
            image.fill_rect(Rect2i(12, 18, 24, 12), accent)
        "profile":
            image.fill_rect(Rect2i(8, 4, 32, 12), accent)
            image.fill_rect(Rect2i(8, 18, 32, 26), base_color)
        "city":
            image.fill_rect(Rect2i(8, 8, 32, 32), base_color)
            image.fill_rect(Rect2i(14, 14, 20, 8), accent)
        "equipment":
            image.fill_rect(Rect2i(8, 8, 32, 32), base_color)
            image.fill_rect(Rect2i(16, 16, 16, 16), accent)
        "talk":
            image.fill_rect(Rect2i(10, 8, 28, 12), accent)
            image.fill_rect(Rect2i(10, 24, 14, 16), base_color)
        "mission":
            image.fill_rect(Rect2i(8, 8, 16, 24), accent)
            image.fill_rect(Rect2i(24, 14, 16, 16), base_color)
        "rest":
            image.fill_rect(Rect2i(16, 8, 16, 8), accent)
            image.fill_rect(Rect2i(8, 18, 32, 12), base_color)
        "options":
            image.fill_rect(Rect2i(8, 8, 32, 32), base_color)
            image.fill_rect(Rect2i(12, 12, 8, 8), accent)
            image.fill_rect(Rect2i(28, 28, 8, 8), accent)
            image.fill_rect(Rect2i(14, 22, 8, 8), accent)
            image.fill_rect(Rect2i(22, 14, 8, 8), accent)
        "schedule":
            image.fill_rect(Rect2i(8, 8, 32, 32), base_color)
            image.fill_rect(Rect2i(8, 16, 32, 8), accent)
            image.fill_rect(Rect2i(16, 8, 16, 16), accent)

    # Add border
    for x in range(size.x):
        image.set_pixel(x, 0, base_color.darkened(0.3))
        image.set_pixel(x, size.y - 1, base_color.darkened(0.3))
    for y in range(size.y):
        image.set_pixel(0, y, base_color.darkened(0.3))
        image.set_pixel(size.x - 1, y, base_color.darkened(0.3))

    return image


func _initialize() -> void:
    generate_missing_icons()
    quit()
extends SceneTree


func _initialize() -> void:
	var generated: Array[String] = ProceduralPlaceholders.generate_all()
	print("Generated %d of %d procedural placeholders." % [
		generated.size(),
		ProceduralPlaceholders.PLACEHOLDER_DEFINITIONS.size()
	])
	quit(0 if generated.size() == ProceduralPlaceholders.PLACEHOLDER_DEFINITIONS.size() else 1)

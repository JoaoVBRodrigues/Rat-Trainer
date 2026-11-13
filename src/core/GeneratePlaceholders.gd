@tool
extends EditorScript

func _run() -> void:
	var created: Array[String] = ProceduralPlaceholders.generate_all()
	print("Generated %d procedural placeholders." % created.size())
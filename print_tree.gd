@tool
extends SceneTree

func _init():
	var scene = load("res://Scripts/Props/Key.glb")
	var file = FileAccess.open("res://key_debug.txt", FileAccess.WRITE)
	if scene:
		var root = scene.instantiate()
		print_tree(root, "", file)
	else:
		file.store_line("SCENE IS NULL!")
	file.close()
	quit()

func print_tree(node: Node, indent: String, file: FileAccess):
	file.store_line(indent + node.name + " (" + node.get_class() + ")")
	if node is MeshInstance3D:
		file.store_line(indent + "  AABB: " + str(node.get_aabb()))
	for child in node.get_children():
		print_tree(child, indent + "  ", file)

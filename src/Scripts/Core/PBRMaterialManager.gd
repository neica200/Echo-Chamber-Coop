extends Node

var floor_material: StandardMaterial3D
var wood_floor_material: StandardMaterial3D
var ceiling_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var rusty_metal_material: StandardMaterial3D
var safe_material: StandardMaterial3D
var door_material: StandardMaterial3D
var plastic_material: StandardMaterial3D
var glass_material: StandardMaterial3D

func _ready():
	_generate_materials()

func _generate_materials():
	# Floor Material (Solid Wood Color)
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.25, 0.2, 0.15)
	floor_material.roughness = 0.8
	floor_material.metallic = 0.0
	
	# Wood Floor (Parquet Color)
	wood_floor_material = StandardMaterial3D.new()
	wood_floor_material.albedo_color = Color(0.3, 0.2, 0.1)
	wood_floor_material.roughness = 0.6
	wood_floor_material.metallic = 0.0
	
	# Ceiling Material
	ceiling_material = StandardMaterial3D.new()
	ceiling_material.albedo_color = Color(0.6, 0.6, 0.6)
	ceiling_material.roughness = 0.95
	ceiling_material.metallic = 0.0

	# Wall Material (Solid Concrete Color)
	wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.4, 0.4, 0.45)
	wall_material.roughness = 0.9
	wall_material.metallic = 0.0

	# Rusty Metal Material
	rusty_metal_material = StandardMaterial3D.new()
	rusty_metal_material.albedo_color = Color(0.45, 0.25, 0.15)
	rusty_metal_material.roughness = 0.8
	rusty_metal_material.metallic = 0.0
	
	# Safe Material (Brushed Steel look but 0 metallic so it doesn't go black)
	safe_material = StandardMaterial3D.new()
	safe_material.albedo_color = Color(0.3, 0.3, 0.35)
	safe_material.roughness = 0.5
	safe_material.metallic = 0.0
	
	# Door Material (Painted Heavy Metal)
	door_material = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.2, 0.35, 0.45)
	door_material.roughness = 0.7
	door_material.metallic = 0.0
	
	# Plastic/Casing Material (Matte Gray for numpad/fusebox)
	plastic_material = StandardMaterial3D.new()
	plastic_material.albedo_color = Color(0.15, 0.15, 0.15)
	plastic_material.roughness = 0.9
	plastic_material.metallic = 0.0
	
	# Glass Material
	glass_material = StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(0.8, 0.9, 1.0, 0.3)
	glass_material.metallic = 0.5
	glass_material.roughness = 0.1
	glass_material.refraction_enabled = true
	glass_material.refraction_scale = 0.05

func apply_material_to_mesh(node: Node, mat_type: String):
	if node == null:
		return
		
	if node.name.find("Button") != -1 or node.name.find("Handle") != -1 or node.name.find("Screen") != -1 or node.name.find("Label") != -1 or node.name.find("Light") != -1:
		return
		
	var mat: StandardMaterial3D
	match mat_type:
		"floor": mat = floor_material
		"wood_floor": mat = wood_floor_material
		"ceiling": mat = ceiling_material
		"wall": mat = wall_material
		"rusty_metal": mat = rusty_metal_material
		"safe": mat = safe_material
		"door": mat = door_material
		"plastic": mat = plastic_material
		"glass": mat = glass_material
		
	if node is MeshInstance3D:
		node.set_surface_override_material(0, mat)
	
	# Apply to all children MeshInstance3D
	for child in node.get_children():
		apply_material_to_mesh(child, mat_type)

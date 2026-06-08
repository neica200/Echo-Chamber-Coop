extends Node

var floor_material: StandardMaterial3D
var wood_floor_material: StandardMaterial3D
var ceiling_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var rusty_metal_material: StandardMaterial3D
var safe_material: StandardMaterial3D
var box_material: StandardMaterial3D
var door_material: StandardMaterial3D
var plastic_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var furniture_material: StandardMaterial3D
var rug_material: StandardMaterial3D

func _ready():
	_generate_materials()

func _generate_materials():
	# Floor Material
	floor_material = StandardMaterial3D.new()
	floor_material.albedo_texture = load("res://Scripts/Textures/drive-download-20260608T150035Z-3-001/Substance_Graph_BaseColor.jpg")
	floor_material.normal_enabled = true
	floor_material.normal_texture = load("res://Scripts/Textures/drive-download-20260608T150035Z-3-001/Substance_Graph_Normal.jpg")
	floor_material.roughness_texture = load("res://Scripts/Textures/drive-download-20260608T150035Z-3-001/Substance_Graph_Roughness.jpg")
	floor_material.ao_enabled = true
	floor_material.ao_texture = load("res://Scripts/Textures/drive-download-20260608T150035Z-3-001/Substance_Graph_AmbientOcclusion.jpg")
	floor_material.heightmap_enabled = true
	floor_material.heightmap_texture = load("res://Scripts/Textures/drive-download-20260608T150035Z-3-001/Substance_Graph_Height.jpg")
	floor_material.heightmap_scale = 0.05
	floor_material.albedo_color = Color(1.0, 1.0, 1.0)
	floor_material.uv1_scale = Vector3(10, 10, 10)
	floor_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	
	# Wood Floor (Același cu podeaua normală acum, pentru a evita ambiguitatea)
	wood_floor_material = floor_material
	
	# Ceiling Material (Metal Roofing)
	ceiling_material = StandardMaterial3D.new()
	ceiling_material.albedo_color = Color(0.8, 0.8, 0.8)
	ceiling_material.roughness = 0.95

	# Wall Material
	wall_material = StandardMaterial3D.new()
	wall_material.albedo_texture = load("res://Scripts/Textures/wall/Tiles_Stone_006_basecolor.png")
	wall_material.normal_enabled = true
	wall_material.normal_texture = load("res://Scripts/Textures/wall/Tiles_Stone_006_normal.png")
	wall_material.roughness_texture = load("res://Scripts/Textures/wall/Tiles_Stone_006_roughness.png")
	wall_material.ao_enabled = true
	wall_material.ao_texture = load("res://Scripts/Textures/wall/Tiles_Stone_006_ambientOcclusion.png")
	wall_material.heightmap_enabled = true
	wall_material.heightmap_texture = load("res://Scripts/Textures/wall/Tiles_Stone_006_height.png")
	wall_material.heightmap_scale = 0.05
	wall_material.albedo_color = Color(1.0, 1.0, 1.0)
	wall_material.uv1_triplanar = false
	wall_material.uv1_scale = Vector3(4, 4, 4) # Scalare uniformă pentru dale de piatră
	wall_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	# Rusty Metal Material
	rusty_metal_material = StandardMaterial3D.new()
	rusty_metal_material.albedo_color = Color(0.5, 0.3, 0.2) # Maroniu-ruginiu
	rusty_metal_material.roughness = 0.9
	
	# Safe Material
	safe_material = StandardMaterial3D.new()
	safe_material.albedo_color = Color(0.4, 0.4, 0.4) # Gri metalic clasic
	safe_material.metallic = 0.5 # Nu prea mare ca să nu fie negru
	safe_material.roughness = 0.5
	
	# Door Material
	door_material = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.35, 0.2, 0.1) # Maro pentru lemn
	door_material.roughness = 0.8
	
	# Box Material
	box_material = StandardMaterial3D.new()
	box_material.albedo_color = Color(0.6, 0.4, 0.2) # Carton
	box_material.roughness = 0.9
	
	# Furniture Material (Desk / Bookshelf)
	furniture_material = StandardMaterial3D.new()
	furniture_material.albedo_color = Color(0.2, 0.1, 0.05) # Maro foarte închis
	furniture_material.roughness = 0.7
	
	# Rug Material
	rug_material = StandardMaterial3D.new()
	rug_material.albedo_texture = load("res://Scripts/Textures/velour_velvet_4k.blend/textures/velour_velvet_diff_4k.jpg")
	rug_material.normal_enabled = true
	rug_material.normal_scale = 0.3 # Velvet mult mai slabut
	rug_material.normal_texture = load("res://Scripts/Textures/velour_velvet_4k.blend/textures/velour_velvet_nor_gl_4k.exr")
	rug_material.roughness_texture = load("res://Scripts/Textures/velour_velvet_4k.blend/textures/velour_velvet_rough_4k.exr")
	rug_material.metallic = 0.0
	rug_material.metallic_specular = 0.0
	rug_material.heightmap_enabled = true
	rug_material.heightmap_texture = load("res://Scripts/Textures/velour_velvet_4k.blend/textures/velour_velvet_disp_4k.png")
	rug_material.heightmap_scale = 0.02
	rug_material.albedo_color = Color(0.3, 0.3, 0.3) # Covor fizic mai întunecat pentru a absorbi lumina
	rug_material.uv1_scale = Vector3(4, 4, 4)
	rug_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	
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
		
	if node.name.find("Button") != -1 or node.name.find("Handle") != -1 or node.name.find("Screen") != -1 or node.name.find("Label") != -1 or node.name.find("Light") != -1 or node.name.find("Plinth") != -1 or node.name.find("Frame") != -1:
		return
		
	var mat: StandardMaterial3D
	match mat_type:
		"floor": mat = floor_material
		"wood_floor": mat = wood_floor_material
		"ceiling": mat = ceiling_material
		"wall": mat = wall_material
		"rusty_metal": mat = rusty_metal_material
		"safe": mat = safe_material
		"box": mat = box_material
		"door": mat = door_material
		"plastic": mat = plastic_material
		"glass": mat = glass_material
		"furniture": mat = furniture_material
		"rug": mat = rug_material
		
	if node is MeshInstance3D:
		node.set_surface_override_material(0, mat)
	
	# Apply to all children MeshInstance3D
	for child in node.get_children():
		apply_material_to_mesh(child, mat_type)

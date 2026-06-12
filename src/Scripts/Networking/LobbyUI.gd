extends Control

const PORT = 7777
const MAX_PLAYERS = 2

@onready var ip_field = $CenterContainer/VBoxContainer/HBoxContainer/IP
@onready var status_label = $CenterContainer/VBoxContainer/Stare
@onready var host_button = $CenterContainer/VBoxContainer/Host
@onready var join_button = $CenterContainer/VBoxContainer/HBoxContainer/Join

func _ready():
	_setup_premium_ui()
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _setup_premium_ui():
	# Background 
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09) # Cyberpunk/Sci-Fi dark blue
	add_child(bg)
	move_child(bg, 0)
	
	# Glassmorphism Panel in spatele formularului
	var panel = Panel.new()
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.12, 0.14, 0.2, 0.85)
	style_panel.border_color = Color(0.3, 0.5, 0.8, 0.3)
	style_panel.border_width_left = 1
	style_panel.border_width_right = 1
	style_panel.border_width_top = 1
	style_panel.border_width_bottom = 1
	style_panel.corner_radius_top_left = 24
	style_panel.corner_radius_top_right = 24
	style_panel.corner_radius_bottom_left = 24
	style_panel.corner_radius_bottom_right = 24
	style_panel.shadow_color = Color(0, 0, 0, 0.6)
	style_panel.shadow_size = 40
	panel.add_theme_stylebox_override("panel", style_panel)
	panel.custom_minimum_size = Vector2(460, 320)
	
	# Muta panelul in CenterContainer
	$CenterContainer.add_child(panel)
	$CenterContainer.move_child(panel, 0)
	
	# Title
	var title = $CenterContainer/VBoxContainer/Titlu
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.2, 0.5, 1.0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	
	# VBox Spacing
	$CenterContainer/VBoxContainer.add_theme_constant_override("separation", 20)
	
	# LineEdit (IP)
	var style_line = StyleBoxFlat.new()
	style_line.bg_color = Color(0.08, 0.1, 0.14)
	style_line.corner_radius_top_left = 12
	style_line.corner_radius_top_right = 12
	style_line.corner_radius_bottom_left = 12
	style_line.corner_radius_bottom_right = 12
	style_line.content_margin_left = 20
	style_line.content_margin_right = 20
	style_line.content_margin_top = 10
	style_line.content_margin_bottom = 10
	style_line.border_width_bottom = 3
	style_line.border_color = Color(0.3, 0.6, 1.0)
	ip_field.add_theme_stylebox_override("normal", style_line)
	ip_field.add_theme_font_size_override("font_size", 18)
	
	# Buttons
	_style_button(join_button, Color(0.2, 0.7, 0.5)) # Smarald vibrant
	_style_button(host_button, Color(0.25, 0.5, 0.9)) # Albastru vibrant
	
	# Status
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _style_button(btn: Button, base_color: Color):
	btn.custom_minimum_size.y = 48
	btn.custom_minimum_size.x = 120
	btn.add_theme_font_size_override("font_size", 18)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color * 0.8
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.border_width_bottom = 4
	normal.border_color = base_color * 0.5
	
	var hover = normal.duplicate()
	hover.bg_color = base_color * 1.1
	hover.border_color = base_color * 0.7
	hover.shadow_color = base_color
	hover.shadow_size = 15
	
	var pressed = normal.duplicate()
	pressed.bg_color = base_color * 0.6
	pressed.border_width_bottom = 0
	pressed.content_margin_top = 4 # Apasa butonul in jos
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_host_pressed():
	NetworkManager.host()
	
	var local_ip = "localhost"
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			local_ip = ip
			break
			
	status_label.text = "Host pornit!\nLocal: " + local_ip + "\n(Dacă jucați pe internet, dă-i IP-ul public din Playit.gg!)"
	host_button.disabled = true
	join_button.disabled = true

func _on_join_pressed():
	var ip = ip_field.text.strip_edges()
	if ip == "":
		status_label.text = "Enter a valid IP!"
		return
	NetworkManager.join(ip)
	status_label.text = "Connecting to " + ip + "..."
	
func _on_player_connected(id):
	status_label.text = "Jucător conectat! ID: " + str(id)

func _on_player_disconnected(id):
	status_label.text = "Jucător deconectat!"

func _on_connected_to_server():
	status_label.text = "Conectat la server!"

func _on_connection_failed():
	status_label.text = "Conexiune eșuată!"

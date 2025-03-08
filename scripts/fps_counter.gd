extends Label

@export var update_interval: float = 0.5  # How often to update the FPS display
var time_passed: float = 0.0
var vsync_enabled: bool = true  # Track VSync state

func _ready():
	# Set initial properties
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	# Set font size and add outline for better visibility
	add_theme_font_size_override("font_size", 16)
	
	# Add a shadow or outline for better visibility against different backgrounds
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_theme_constant_override("outline_size", 1)
	
	# Set a custom color for better visibility
	add_theme_color_override("font_color", Color(1, 1, 0, 1))  # Yellow text
	
	# Check initial VSync state
	vsync_enabled = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	update_fps_text()

func _process(delta):
	time_passed += delta
	
	# Update the FPS counter at the specified interval
	if time_passed >= update_interval:
		update_fps_text()
		time_passed = 0.0
	
	# Toggle VSync with the Home key
	if Input.is_action_just_pressed("ui_home"):  # Home key by default
		toggle_vsync()

func update_fps_text():
	# Get the current FPS
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	
	# Update the label text with FPS and VSync status
	var vsync_status = "VSync: ON" if vsync_enabled else "VSync: OFF"
	text = "FPS: " + str(round(fps)) + " | " + vsync_status + " (Home to toggle)"
#
func toggle_vsync():
	# Toggle VSync state
	vsync_enabled = !vsync_enabled
	
	# Apply the new VSync setting
	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Update the display immediately
	update_fps_text()

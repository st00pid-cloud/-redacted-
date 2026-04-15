extends Node3D
class_name LevelEnvironment

## LevelEnvironment.gd
## Attach to your level root or add as a child.
## Creates a dark horror atmosphere: dim ambient, fog, and emergency-style lights.
## Also spawns subtle dust particles near the camera.

@export var ambient_energy: float = 0.05
@export var fog_enabled: bool = true
@export var fog_density: float = 0.02
@export var fog_color: Color = Color(0.02, 0.03, 0.02)

var _world_env: WorldEnvironment
var _dust_particles: GPUParticles3D

func _ready() -> void:
	_setup_environment()
	_setup_dust_particles()

func _setup_environment() -> void:
	# Check if a WorldEnvironment already exists
	_world_env = _find_existing_world_env()
	if not _world_env:
		_world_env = WorldEnvironment.new()
		add_child(_world_env)
	
	var env = Environment.new()
	
	# Very dark ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.08, 0.12, 0.08)
	env.ambient_light_energy = ambient_energy
	
	# Dark background
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	
	# Fog for depth/atmosphere
	env.fog_enabled = fog_enabled
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	
	# Slight glow for terminal screens
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	
	# Tonemap for dark scenes
	env.tonemap_mode = Environment.TONE_MAP_FILMIC
	env.tonemap_exposure = 0.8
	
	_world_env.environment = env

func _setup_dust_particles() -> void:
	_dust_particles = GPUParticles3D.new()
	_dust_particles.amount = 60
	_dust_particles.lifetime = 8.0
	_dust_particles.visibility_aabb = AABB(Vector3(-10, -3, -10), Vector3(20, 8, 20))
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -0.2, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.15
	mat.gravity = Vector3(0, -0.02, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(8, 4, 8)
	mat.scale_min = 0.01
	mat.scale_max = 0.03
	mat.color = Color(0.5, 0.6, 0.5, 0.15)
	
	_dust_particles.process_material = mat
	
	# Simple quad mesh for dust motes
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.04, 0.04)
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.6, 0.7, 0.6, 0.2)
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mesh_mat
	_dust_particles.draw_pass_1 = mesh
	
	add_child(_dust_particles)

func _find_existing_world_env() -> WorldEnvironment:
	for child in get_tree().root.get_children():
		if child is WorldEnvironment:
			return child
		for sub in child.get_children():
			if sub is WorldEnvironment:
				return sub
	return null

## Call this to add an emergency-style flickering light at a position
static func create_emergency_light(parent: Node3D, pos: Vector3, color: Color = Color(0.8, 0.2, 0.1)) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 8.0
	light.omni_attenuation = 1.5
	light.shadow_enabled = true
	parent.add_child(light)
	
	# Flicker effect via script
	var flicker = LightFlicker.new()
	light.add_child(flicker)
	
	return light

## Call this to add a dim overhead fluorescent (cool white, steady with occasional flicker)
static func create_fluorescent_light(parent: Node3D, pos: Vector3) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.position = pos
	light.light_color = Color(0.7, 0.85, 0.7)
	light.light_energy = 0.6
	light.omni_range = 12.0
	light.omni_attenuation = 1.2
	light.shadow_enabled = true
	parent.add_child(light)
	
	var flicker = LightFlicker.new()
	flicker.flicker_chance = 0.005  # rare flicker
	flicker.min_energy = 0.3
	flicker.max_energy = 0.7
	light.add_child(flicker)
	
	return light

class_name PlayerController extends RigidBody3D

@export var playerId := "player1"

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

@export_group("Movement feel")
@export var time_to_reach_speed := 0.12
@export var braking_acceleration := 45.0
@export var air_acceleration_multiplier := 0.6

@export_group("Jump feel")
@export var fall_gravity_multiplier := 2.25
@export var low_jump_gravity_multiplier := 3.0

@export_group("Movement debuff")
@export var debuff_move_speed := 2.0

@export_group("Physics feel")
@export_range(0.0, 1.0) var player_friction := 0.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 6.0

@export var stick_look_speed := 3.0
@export var stick_deadzone := 0.15
@export var invert_y := false

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _wall_normal: Vector3 = Vector3.ZERO

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = $ReplaceWithPlayerScene

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	
	if physics_material_override == null:
		var mat := PhysicsMaterial.new()
		mat.friction = player_friction
		mat.rough = false
		physics_material_override = mat
	else:
		physics_material_override.friction = player_friction
		physics_material_override.rough = false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var combined: Vector3 = Vector3.ZERO
	var count: int = state.get_contact_count()
	for i in count:
		var local_normal: Vector3 = state.get_contact_local_normal(i)
		var world_normal: Vector3 = global_basis * local_normal
		if absf(world_normal.y) < 0.5:
			combined += world_normal

	if combined.length_squared() < 0.0001:
		_wall_normal = Vector3.ZERO
	else:
		var normalizedCombined := combined.normalized()
		normalizedCombined.y = 0.0
		_wall_normal = Vector3.ZERO if normalizedCombined.length_squared() < 0.0001 else normalizedCombined.normalized()

func _isGrounded() -> bool:
	var space_state := self.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(self.global_position + Vector3.UP * .5, self.global_position + Vector3(0, -.75, 0), 1 << 7)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := space_state.intersect_ray(query)

	return !result.is_empty()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = (event as InputEventMouseMotion).screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:	
	var grounded := _isGrounded()

	var stick := Input.get_vector(
		"look_left_%s" % [playerId],
		"look_right_%s" % [playerId],
		"look_up_%s" % [playerId],
		"look_down_%s" % [playerId]
	)

	if stick.length() < stick_deadzone:
		stick = Vector2.ZERO
	else:
		stick = stick.normalized() * ((stick.length() - stick_deadzone) / (1.0 - stick_deadzone))

	if invert_y:
		stick.y = -stick.y

	_camera_input_direction += stick * stick_look_speed

	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector(
		"move_left_%s" % [playerId],
		"move_right_%s" % [playerId],
		"move_up_%s" % [playerId],
		"move_down_%s" % [playerId]
	)
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	if (
		_wall_normal != Vector3.ZERO
		and move_direction.length_squared() > 0.0
		and move_direction.dot(_wall_normal) < 0.0
	):
		move_direction = move_direction.slide(_wall_normal)

	var current_speed := move_speed
	if PlayerStatus.has_debuff("mask"):
		current_speed = debuff_move_speed

	var linearVelocity: Vector3 = self.linear_velocity
	var horizontal_velocity: Vector3 = Vector3(linearVelocity.x, 0.0, linearVelocity.z)
	var desired_velocity: Vector3 = move_direction * current_speed
	var delta_velocity: Vector3 = desired_velocity - horizontal_velocity

	var timeToReachMaxSpeed: float = maxf(time_to_reach_speed, 0.001)
	var desired_accelleration: Vector3 = delta_velocity / timeToReachMaxSpeed

	var has_move_input: bool = raw_input.length() > 0.05
	var max_accelleration: float = acceleration if has_move_input else braking_acceleration
	if !grounded:
		max_accelleration *= air_acceleration_multiplier

	desired_accelleration = desired_accelleration.limit_length(max_accelleration)
	
	self.apply_central_force(desired_accelleration * self.mass)

	var horizontal_clamped: Vector3 = horizontal_velocity.limit_length(current_speed)
	
	if _wall_normal != Vector3.ZERO and horizontal_clamped.dot(_wall_normal) < 0.0:
		horizontal_clamped = horizontal_clamped.slide(_wall_normal)
	self.linear_velocity = Vector3(horizontal_clamped.x, linearVelocity.y, horizontal_clamped.z)

	var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var jump_action := "jump_%s" % [playerId]
	if !grounded:
		if self.linear_velocity.y < 0.0 and fall_gravity_multiplier > 1.0:
			self.apply_central_force(Vector3.DOWN * gravity * (fall_gravity_multiplier - 1.0) * self.mass)
		elif self.linear_velocity.y > 0.0 and !Input.is_action_pressed(jump_action) and low_jump_gravity_multiplier > 1.0:
			self.apply_central_force(Vector3.DOWN * gravity * (low_jump_gravity_multiplier - 1.0) * self.mass)
	
	if !PlayerStatus.has_debuff("mask"):
		var is_starting_jump := Input.is_action_just_pressed(jump_action) and grounded

		if is_starting_jump:
			self.apply_central_impulse(Vector3.UP * jump_impulse * self.mass)

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

extends RigidBody3D

@export var playerId := "player1"

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 6.0

@export var stick_look_speed := 3.0
@export var stick_deadzone := 0.15
@export var invert_y := false

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = $ReplaceWithPlayerScene

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

	var force := move_direction * acceleration;
	self.apply_central_force(force * self.mass)

	# var world := self.get_world_3d()
	# world.

	var is_starting_jump := Input.is_action_just_pressed("jump_%s" % [playerId]) # and is_on_floor()
	if is_starting_jump:
		self.apply_central_impulse(Vector3.UP * jump_impulse * self.mass)

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

extends CharacterBody3D

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
var _gravity := -30.0

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

	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta

	var is_starting_jump := Input.is_action_just_pressed("jump_%s" % [playerId]) and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse

#	var collided := move_and_slide()
#	if collided:
#		const mass := 15.
#		for i in get_slide_collision_count():
#			var collision := get_slide_collision(i)
#			var collider := collision.get_collider()
#			if collider is RigidBody3D:
#				var rigidbody := collider as RigidBody3D
#
#				var normal := collision.get_normal()
#				var relative_velocity := self.velocity - rigidbody.linear_velocity
#
#				const elasticity := 1.
#				var force := -(1. + elasticity) * (relative_velocity.dot(normal) / (1. / mass + 1. / rigidbody.mass))
#
#				self.velocity += (normal * force) / mass
#				rigidbody.apply_impulse()
#				# Objects with more mass than us should be harder to push. But doesn't really make sense to push faster than we are going
#				var mass_ratio: float = min(1., MY_APPROX_MASS_KG / rigidbody.mass)
#				# Optional add: Don't push object at all if it's 4x heavier or more
#				if mass_ratio < 0.25:
#					continue
#				# Don't push object from above/below
#				push_dir.y = 0
#				# 5.0 is a magic number, adjust to your needs
#				var push_force := mass_ratio # * 5.0
#				rigidbody.apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, collision.get_position() - rigidbody.global_position)
#				print("applying force %f" % (push_dir.length() * velocity_diff_in_push_dir * push_force))

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

class_name ItemDamagerComponent extends ItemComponent

@export var hiddenTimeBeforeReset: float = 3.
@export var disappearOnGroundTouch: bool = true

@export var item: Item
@export var rigidbody: RigidBody3D
@export var collider: CollisionShape3D
@export var view: Node3D

signal onDestroyed

var originalPosition: Vector3

var isThrown: bool
var throwerPlayer: PlayerController

var resetMoment: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rigidbody.connect("body_entered", _on_body_entered)

	originalPosition = item.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	if now >= resetMoment:
		_reset()

func _on_body_entered(body: Node) -> void:
	if !isThrown:
		return

	if body is PlayerController:
		var playerController: PlayerController = body
		if playerController != throwerPlayer:
			playerController.stun()

			var playerMaskActorComponent: ActorMaskEquipperComponent = playerController.actor.get_component(ActorMaskEquipperComponent)
			if playerMaskActorComponent != null:
				playerMaskActorComponent.drop()
	else:
		_disable()
		resetMoment = Time.get_unix_time_from_system() + hiddenTimeBeforeReset
		onDestroyed.emit()

func _enable() -> void:
	collider.set_disabled(false)
	view.visible = true
	rigidbody.freeze = false

func _disable() -> void:
	collider.set_disabled(true)
	view.visible = false
	rigidbody.freeze = true
	rigidbody.linear_velocity = Vector3.ZERO

func _reset() -> void:
	var now := Time.get_unix_time_from_system()
	if now < resetMoment:
		return

	resetMoment = INF
	item.global_position = originalPosition
	isThrown = false
	throwerPlayer = null
	_enable()

func start_throw(throwerPlayer: PlayerController) -> void:
	isThrown = true
	self.throwerPlayer = throwerPlayer

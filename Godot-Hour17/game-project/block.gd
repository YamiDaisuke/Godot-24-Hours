extends Spatial

signal won()

enum Direction { UP, DOWN, RIGHT, LEFT }
enum Orientation { PARALLEL, ORTHOGONAL }
enum RestPosition { STANDING, LYING }

const movement_duration = 0.2;

export (NodePath) var start_point

var is_turning = false
var interpolation = 0
var rotation_direction = null
var won = false
var lost = false
var respawning = false

var rotations = 0
var orientation = PARALLEL
var rest_position = STANDING

var right_shift = Vector3(0.5, -1, 0)
var down_shift = Vector3(0, -1, 0.5)

func _input(event):
	if event.is_action_pressed("right"):
		start_turning(RIGHT)
	elif event.is_action_pressed("down"):
		start_turning(DOWN)
	elif event.is_action_pressed("left"):
		start_turning(LEFT)
	elif event.is_action_pressed("up"):
		start_turning(UP)

func _physics_process(delta):
	if is_turning:
		var step = (delta / movement_duration)
		var angle = (PI / 2.0) * step
		var body = $RigidBody
		match rotation_direction:
			RIGHT:
				body.transform = body.transform.rotated(Vector3(0, 0, -1), angle)
			DOWN:
				body.transform = body.transform.rotated(Vector3(1, 0, 0), angle)
			LEFT:
				body.transform = body.transform.rotated(Vector3(0, 0, 1), angle)
			UP:
				body.transform = body.transform.rotated(Vector3(-1, 0, 0), angle)

		interpolation += step

		if interpolation >= 1:
			is_turning = false
			interpolation = 0
			update_shifts()

func start_turning(direction):
	if respawning or won or lost or interpolation != 0 or not $GravityTimer.is_stopped(): return
	is_turning = true
	rotations += 1
	match direction:
		RIGHT:
			rotation_direction = RIGHT
			adjust_transform(right_shift)
		DOWN:
			rotation_direction = DOWN
			adjust_transform(down_shift)
		LEFT:
			rotation_direction = LEFT
			adjust_transform(right_shift * Vector3(-1, 1, 0))
		UP:
			rotation_direction = UP
			adjust_transform(down_shift * Vector3(0, 1, -1))
	adjust_orientation()

func adjust_transform(shift):
	translation += $RigidBody.translation + shift
	$RigidBody.translation = -shift

func adjust_orientation():
	if rest_position == LYING:
		match rotation_direction:
			RIGHT, LEFT:
				if orientation == PARALLEL:
					rest_position = STANDING
			UP, DOWN:
				if orientation == ORTHOGONAL:
					rest_position = STANDING
	else: # if rest_position == STANDING:
		rest_position = LYING
		match rotation_direction:
			RIGHT, LEFT:
				orientation = PARALLEL
			UP, DOWN:
				orientation = ORTHOGONAL

func update_shifts():
	if rest_position == STANDING:
		right_shift = Vector3(0.5, -1, 0)
		down_shift = Vector3(0, -1, 0.5)
	else: match orientation:
		PARALLEL:
			right_shift = Vector3(1, -0.5, 0)
			down_shift = Vector3(0, -0.5, 0.5)
		ORTHOGONAL:
			right_shift = Vector3(0.5, -0.5, 0)
			down_shift = Vector3(0, -0.5, 1)

func win():
	won = true
	emit_signal("won")

func lose():
	lost = true
	$RespawnTimer.start()

func reset_properties():
	is_turning = false
	interpolation = 0
	rotation_direction = null
	won = false
	lost = false

	rotations = 0
	orientation = PARALLEL
	rest_position = STANDING

	right_shift = Vector3(0.5, -1, 0)
	down_shift = Vector3(0, -1, 0.5)

func zero_gravity():
	$RigidBody.gravity_scale = 0
	respawning = false

func respawn():
	if respawning: return
	translation = get_node(start_point).translation
	lost = false
	won = false
	respawning = true
	yield(get_tree(), "physics_frame")
	var body = $RigidBody
	body.gravity_scale = 1
	body.translation = Vector3()
	body.rotation = Vector3()
	body.angular_velocity = Vector3()
	body.linear_velocity = Vector3()
	reset_properties()

	$GravityTimer.start()

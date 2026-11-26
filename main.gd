extends Node3D
var player: CharacterBody3D
var camera: Camera3D
var cars: Array[CharacterBody3D] = []
var driving: CharacterBody3D
var movement := Vector2.ZERO
var buttons := {}
var rng := RandomNumberGenerator.new()

func block(pos: Vector3, dimensions: Vector3, color: Color, solid := true) -> Node3D:
	var root := StaticBody3D.new()
	add_child(root)
	root.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = dimensions
		collision.shape = box
		root.add_child(collision)
	return root

func _ready():
	rng.seed = 2026
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#85c9ef")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-35,0)
	add_child(sun)
	block(Vector3(0,-0.5,0),Vector3(400,1,400),Color("#aaa58d"))
	for x in range(-5,6):
		block(Vector3(x*32,0.02,0),Vector3(9,0.04,380),Color("#444752"),false)
		block(Vector3(0,0.03,x*32),Vector3(380,0.04,9),Color("#444752"),false)
	for x in range(-5,5):
		for z in range(-5,5):
			var h := rng.randf_range(5,25)
			block(Vector3(x*32+16,h/2,z*32+16),Vector3(17,h,17),Color.from_hsv(rng.randf(),0.27,0.85))
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(0,1,0)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	collider.shape = capsule
	player.add_child(collider)
	var avatar := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.height = 1.8
	body.radius = 0.35
	avatar.mesh = body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e86c80")
	avatar.material_override = mat
	player.add_child(avatar)
	for i in range(12):
		var car := CharacterBody3D.new()
		add_child(car)
		car.position = Vector3(2,0.65,8+i*12)
		var hit := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = Vector3(2,1.3,4)
		hit.shape = bounds
		car.add_child(hit)
		var body_mesh := MeshInstance3D.new()
		var car_box := BoxMesh.new()
		car_box.size = Vector3(2,0.8,4)
		body_mesh.mesh = car_box
		var paint := StandardMaterial3D.new()
		paint.albedo_color = Color.from_hsv(rng.randf(),0.8,0.8)
		body_mesh.material_override = paint
		car.add_child(body_mesh)
		var cabin := MeshInstance3D.new()
		var cabin_box := BoxMesh.new()
		cabin_box.size = Vector3(1.6,0.65,1.9)
		cabin.mesh = cabin_box
		cabin.position.y = 0.6
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color("#34495e")
		cabin.material_override = glass
		car.add_child(cabin)
		cars.append(car)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.position = player.position + Vector3(0,4,7)
	camera.look_at(player.position)
	var ui := CanvasLayer.new()
	add_child(ui)
	var label := Label.new()
	label.text = "LEONIDA • ПРОТОТИП"
	label.position = Vector2(16,12)
	ui.add_child(label)
	for item in [["↑",Vector2(60,235),Vector2(0,-1)],["↓",Vector2(60,300),Vector2(0,1)],["←",Vector2(5,300),Vector2(-1,0)],["→",Vector2(115,300),Vector2(1,0)]]:
		var b := Button.new()
		b.text = item[0]
		b.position = item[1]
		b.size = Vector2(52,52)
		ui.add_child(b)
		buttons[b] = item[2]

	var enter := Button.new()
	enter.text = "Сесть / выйти"
	enter.position = Vector2(480,280)
	enter.size = Vector2(145,60)
	ui.add_child(enter)
	enter.pressed.connect(toggle_car)

func toggle_car():
	if is_instance_valid(driving):
		player.position = driving.position + driving.transform.basis.x * 2.5 + Vector3.UP
		player.show()
		player.get_node("CollisionShape3D").set_deferred("disabled",false)
		driving = null
		return
	for car in cars:
		if player.position.distance_to(car.position) < 5:
			driving = car
			player.hide()
			player.get_node("CollisionShape3D").set_deferred("disabled",true)
			break

func _physics_process(delta):
	movement = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	for b in buttons:
		if b.button_pressed:
			movement += buttons[b]
	movement = movement.limit_length()
	if is_instance_valid(driving):
		driving.rotate_y(-movement.x*delta*1.8)
		driving.velocity = driving.transform.basis.z * movement.y * 20
		driving.move_and_slide()
		player.position = driving.position
		camera.position = camera.position.lerp(driving.position + driving.transform.basis.z*8 + Vector3.UP*4, minf(delta*6,1))
		camera.look_at(driving.position)
		return
	player.velocity.x = movement.x*7
	player.velocity.z = movement.y*7
	if not player.is_on_floor():
		player.velocity.y -= 20*delta
	player.move_and_slide()
	camera.position = camera.position.lerp(player.position+Vector3(0,4,7),minf(delta*8,1))
	camera.look_at(player.position+Vector3(0,0.5,0))

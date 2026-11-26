extends Node3D
var player: CharacterBody3D
var camera: Camera3D
var pedestrians: Array[Node3D] = []
var hud: Label
var mission := 0
var cash := 0
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
	# Coastal district and island causeway
	block(Vector3(0,-0.35,205),Vector3(400,0.5,10),Color("#e8cf91"))
	block(Vector3(0,-0.8,280),Vector3(600,0.3,150),Color("#268fae"),false)
	block(Vector3(0,-0.5,275),Vector3(12,1,150),Color("#555b64"))
	block(Vector3(0,-0.5,370),Vector3(120,1,60),Color("#d6c69a"))
	for i in range(16):
		var p := Vector3(-180+i*23,0,190)
		block(p+Vector3(0,2,0),Vector3(0.45,4,0.45),Color("#856341"),false)
		for j in range(5):
			var leaf := block(p+Vector3(0,4,0),Vector3(0.8,0.25,3.5),Color("#388d50"),false)
			leaf.rotation.y = j*TAU/5
	for i in range(8):
		block(Vector3(-48+i*13,2,375),Vector3(9,4,12),Color("#f2b69d"))
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(0,1,0)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	collider.shape = capsule
	collider.name = "CollisionShape3D"
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
	for i in range(24):
		var npc := Node3D.new()
		add_child(npc)
		npc.position = Vector3(5.5,0,-140+i*12)
		var model := MeshInstance3D.new()
		var mesh := CapsuleMesh.new()
		mesh.height = 1.65
		mesh.radius = 0.28
		model.mesh = mesh
		model.position.y = 0.85
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(rng.randf(),0.6,0.85)
		model.material_override = material
		npc.add_child(model)
		pedestrians.append(npc)
	var ui := CanvasLayer.new()
	add_child(ui)
	var label := Label.new()
	hud = label
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
		b.button_down.connect(func(): b.set_meta("held",true))
		b.button_up.connect(func(): b.set_meta("held",false))

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
	for i in range(pedestrians.size()):
		var npc := pedestrians[i]
		npc.position.z += delta * (1.2 if i % 2 == 0 else -1.2)
		if absf(npc.position.z) > 175:
			npc.position.z = -signf(npc.position.z)*174
	if mission == 0 and player.position.z > 180:
		mission = 1
		cash += 250
	if mission == 1 and player.position.z > 350:
		mission = 2
		cash += 500
	hud.text = "LEONIDA   $%d   HP 100\\n%s" % [cash, ["Доберись до пляжа","Пересеки мост","Задания выполнены"][mission]]
	movement = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	for b in buttons:
		if b.button_pressed or (b.has_meta("held") and b.get_meta("held")):
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

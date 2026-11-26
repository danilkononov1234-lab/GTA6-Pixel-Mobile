extends Node3D
var player: CharacterBody3D
var camera: Camera3D
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

func _physics_process(delta):
	movement = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	for b in buttons:
		if b.button_pressed:
			movement += buttons[b]
	movement = movement.limit_length()
	player.velocity.x = movement.x*7
	player.velocity.z = movement.y*7
	if not player.is_on_floor():
		player.velocity.y -= 20*delta
	player.move_and_slide()
	camera.position = camera.position.lerp(player.position+Vector3(0,4,7),minf(delta*8,1))
	camera.look_at(player.position+Vector3(0,0.5,0))

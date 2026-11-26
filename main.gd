extends Node3D

var view: Street
func _ready():
	view = Street.new()
	add_child(view)

class Street extends Node2D:
	var distance := 0.0
	var lane := 0.0
	var walking := false
	var driving := false
	var controls := {}
	var cash := 0
	func _ready():
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for item in [["↑",Vector2(65,245)],["↓",Vector2(65,300)],["←",Vector2(10,300)],["→",Vector2(120,300)],["Сесть / выйти",Vector2(475,300)]]:
			var b := Button.new()
			b.text = item[0]
			b.position = item[1]
			b.size = Vector2(52,50) if item[0].length()==1 else Vector2(150,50)
			b.focus_mode = Control.FOCUS_NONE
			add_child(b)
			controls[item[0]] = b
			if item[0].length()>1:
				b.pressed.connect(func(): driving = not driving)
	func _process(dt):
		var v := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		if controls["↑"].button_pressed: v.y -= 1
		if controls["↓"].button_pressed: v.y += 1
		if controls["←"].button_pressed: v.x -= 1
		if controls["→"].button_pressed: v.x += 1
		walking = v.length()>0.1
		distance += -v.y*dt*(24.0 if driving else 7.0)
		lane = clampf(lane+v.x*dt*2.0,-2.8,2.8)
		queue_redraw()
	func poly(points: Array, c: String):
		draw_colored_polygon(PackedVector2Array(points),Color(c))
	func rect(x:float,y:float,w:float,h:float,c:String):
		draw_rect(Rect2(x,y,w,h),Color(c))
	func project(x:float,y:float,z:float)->Vector2:
		var k := 145.0/maxf(z,0.5)
		return Vector2(320+(x-lane)*k,125+(2.1-y)*k)
	func _draw():
		rect(0,0,640,360,"#86c9d6")
		rect(0,125,640,235,"#d8bba0")
		for i in range(22):
			var x := float(i*31)
			var h := float(12+(i*37)%65)
			rect(x,125-h,25,h,"#7596a5")
			for j in range(int(h/9)):
				rect(x+4,125-h+j*9,3,4,"#c1d3cf")
		poly([Vector2(305,125),Vector2(335,125),project(4,0,1.25),project(-4,0,1.25)],"#454b59")
		for i in range(40,0,-1):
			var z := float(i)*3.0-fposmod(distance,3.0)
			if z<1.4: continue
			for side in [-1,1]:
				var a := project(side*4.0,0,z)
				var b := project(side*4.0,0,z+2.8)
				draw_line(a,b,Color("#f0d6ae"),maxf(1,3/z))
			poly([project(-0.06,0,z),project(0.06,0,z),project(0.06,0,z+1.2),project(-0.06,0,z+1.2)],"#e9ce83")
		for i in range(18,0,-1):
			var z := float(i)*7.0-fposmod(distance,7.0)
			if z<2.0: continue
			for side in [-1,1]:
				facade(float(side),z,i)
				if i%2==0: palm(float(side)*5.1,z)
		car(1.8,7.0+fposmod(-distance,10.0))
		if driving: car(0,1.8)
		else: hero()
		draw_circle(Vector2(52,190),40,Color("#273b46"))
		for i in range(-2,3):
			var q := float(i*15)
			var e := sqrt(36.0*36.0-q*q)
			draw_line(Vector2(52+q,190-e),Vector2(52+q,190+e),Color("#a6a69a"),3)
			draw_line(Vector2(52-e,190+q),Vector2(52+e,190+q),Color("#a6a69a"),3)
		draw_circle(Vector2(52,190),4,Color.WHITE)
		draw_arc(Vector2(52,190),40,0,TAU,48,Color("#e8d9b5"),2)
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(465,25),"$%06d  HP 100"%cash,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
		draw_string(font,Vector2(465,43),"LEONIDA",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#fff0c5"))
	func facade(side:float,z:float,i:int):
		var x := side*6.0
		var h := float(4+i%4)
		var a := project(x,0,z)
		var b := project(x,0,z+6.5)
		var c := project(x,h,z+6.5)
		var d := project(x,h,z)
		var palette := ["#e0b797","#d5c7a4","#b4c7bc","#d9a6a0"]
		poly([a,b,c,d],palette[i%4])
		poly([a,project(x+side*4,0,z),project(x+side*4,h,z),d],"#8c8b83")
		for floor_i in range(int(h/1.5)):
			var y := 0.45+floor_i*1.5
			for j in range(3):
				var zz := z+0.5+j*2.0
				poly([project(x,y,zz),project(x,y,zz+1.15),project(x,y+0.85,zz+1.15),project(x,y+0.85,zz)],"#405762")
				draw_line(project(x,y+0.4,zz),project(x,y+0.4,zz+1.15),Color("#91a5a1"),1)
		draw_line(a,b,Color("#776f67"),2)
		draw_line(d,c,Color("#fff0d0"),2)
	func palm(x:float,z:float):
		var p := project(x,0,z)
		var t := project(x+0.35,4.7,z)
		var k := 145.0/z
		draw_line(p,t,Color("#735a43"),maxf(1,k*0.18))
		for j in range(7):
			var angle := float(j)*TAU/7.0
			var end := t+Vector2(cos(angle)*k*1.35,sin(angle)*k*0.48+absf(cos(angle))*k*0.3)
			poly([t,t+Vector2(0,-k*0.2),end,t.lerp(end,0.6)+Vector2(0,k*0.16)],"#376e53" if j%2==0 else "#50834c")
	func car(x:float,z:float):
		var p := project(x,0,z)
		var k := 145.0/z
		draw_rect(Rect2(p-Vector2(k*0.95,k*0.55),Vector2(k*1.9,k*0.65)),Color("#252936"))
		for side in [-1,1]:
			draw_circle(p+Vector2(side*k*0.73,0),k*0.22,Color("#20232b"))
		poly([p+Vector2(-k,-k*0.2),p+Vector2(-k*0.85,-k*0.65),p+Vector2(k*0.85,-k*0.65),p+Vector2(k,-k*0.2)],"#d7d5bb")
		poly([p+Vector2(-k*0.7,-k*0.65),p+Vector2(-k*0.45,-k*1.05),p+Vector2(k*0.45,-k*1.05),p+Vector2(k*0.7,-k*0.65)],"#394d5e")
		for side in [-1,1]:
			draw_rect(Rect2(p+Vector2(side*k*0.68-k*0.15,-k*0.35),Vector2(k*0.3,k*0.13)),Color("#d84b49"))
	func hero():
		var p := Vector2(320,245)
		var bob := sin(Time.get_ticks_msec()*0.012)*2.0 if walking else 0.0
		p.y += bob
		draw_set_transform(p,0,Vector2(1.4,1.4))
		draw_ellipse_shadow()
		poly([Vector2(-12,12),Vector2(12,12),Vector2(10,48),Vector2(1,48),Vector2(0,24),Vector2(-3,48),Vector2(-12,48)],"#283d56")
		rect(-11,19,4,26,"#50647b")
		rect(5,19,4,26,"#50647b")
		rect(-13,47,12,4,"#24252b")
		rect(1,47,12,4,"#24252b")
		poly([Vector2(-9,-25),Vector2(-19,-20),Vector2(-23,-4),Vector2(-21,13),Vector2(-16,16),Vector2(-13,-5),Vector2(-8,-13)],"#a96e4d")
		poly([Vector2(9,-25),Vector2(19,-20),Vector2(23,-4),Vector2(21,13),Vector2(16,16),Vector2(13,-5),Vector2(8,-13)],"#c38a60")
		poly([Vector2(-10,-26),Vector2(-15,-18),Vector2(-11,12),Vector2(11,12),Vector2(15,-18),Vector2(10,-26),Vector2(5,-18),Vector2(-5,-18)],"#e9dfc8")
		poly([Vector2(-11,-15),Vector2(-7,-12),Vector2(-8,6),Vector2(-3,10),Vector2(-11,10)],"#b5ad9e")
		rect(-10,12,20,4,"#43352f")
		rect(-5,-31,10,12,"#a96e4d")
		poly([Vector2(-9,-46),Vector2(-5,-50),Vector2(6,-50),Vector2(10,-45),Vector2(9,-33),Vector2(5,-29),Vector2(-6,-29),Vector2(-10,-35)],"#b87e56")
		poly([Vector2(-10,-46),Vector2(-6,-51),Vector2(6,-51),Vector2(11,-46),Vector2(9,-36),Vector2(5,-34),Vector2(-7,-35),Vector2(-10,-40)],"#352b2a")
		rect(-6,-48,10,2,"#594039")
		draw_set_transform(Vector2.ZERO)
	func draw_ellipse_shadow():
		draw_colored_polygon(PackedVector2Array([Vector2(-20,49),Vector2(-12,45),Vector2(15,45),Vector2(23,49),Vector2(14,53),Vector2(-15,53)]),Color("#30343b"))

class_name TitleBackdrop
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)

	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.060, 0.075, 0.065))
	_draw_sky(viewport_size)
	_draw_far_hills(viewport_size)
	_draw_road(viewport_size)
	_draw_grass_layers(viewport_size)
	_draw_horse_shapes(viewport_size)
	_draw_protagonist_silhouette(viewport_size)
	_draw_vignette(viewport_size)


func _draw_sky(viewport_size: Vector2) -> void:
	for band in range(9):
		var t := float(band) / 8.0
		var color := Color(0.095 + t * 0.035, 0.115 + t * 0.030, 0.105 + t * 0.015)
		draw_rect(Rect2(0.0, t * viewport_size.y * 0.62, viewport_size.x, viewport_size.y * 0.09), color)
	for streak in range(11):
		var y := viewport_size.y * (0.12 + float(streak % 5) * 0.085)
		var x := -80.0 + float(streak) * viewport_size.x / 8.0
		draw_line(Vector2(x, y), Vector2(x + viewport_size.x * 0.34, y - 22.0), Color(0.690, 0.620, 0.500, 0.075), 18.0)


func _draw_far_hills(viewport_size: Vector2) -> void:
	var horizon := viewport_size.y * 0.54
	var back := PackedVector2Array([
		Vector2(0.0, horizon),
		Vector2(viewport_size.x * 0.16, horizon - 58.0),
		Vector2(viewport_size.x * 0.35, horizon - 22.0),
		Vector2(viewport_size.x * 0.52, horizon - 76.0),
		Vector2(viewport_size.x * 0.76, horizon - 32.0),
		Vector2(viewport_size.x, horizon - 66.0),
		Vector2(viewport_size.x, viewport_size.y),
		Vector2(0.0, viewport_size.y),
	])
	draw_colored_polygon(back, Color(0.075, 0.105, 0.080))
	var front := PackedVector2Array([
		Vector2(0.0, horizon + 54.0),
		Vector2(viewport_size.x * 0.20, horizon - 10.0),
		Vector2(viewport_size.x * 0.44, horizon + 34.0),
		Vector2(viewport_size.x * 0.70, horizon - 20.0),
		Vector2(viewport_size.x, horizon + 20.0),
		Vector2(viewport_size.x, viewport_size.y),
		Vector2(0.0, viewport_size.y),
	])
	draw_colored_polygon(front, Color(0.090, 0.150, 0.095))


func _draw_road(viewport_size: Vector2) -> void:
	var center_x := viewport_size.x * 0.52
	var top_y := viewport_size.y * 0.50
	var road := PackedVector2Array([
		Vector2(center_x - 88.0, top_y),
		Vector2(center_x + 80.0, top_y),
		Vector2(viewport_size.x * 0.76, viewport_size.y),
		Vector2(viewport_size.x * 0.25, viewport_size.y),
	])
	draw_colored_polygon(road, Color(0.205, 0.145, 0.095))
	draw_line(Vector2(center_x - 24.0, top_y + 16.0), Vector2(viewport_size.x * 0.43, viewport_size.y), Color(0.560, 0.430, 0.255, 0.32), 4.0)
	draw_line(Vector2(center_x + 26.0, top_y + 14.0), Vector2(viewport_size.x * 0.60, viewport_size.y), Color(0.560, 0.430, 0.255, 0.26), 4.0)
	for track in range(10):
		var y := top_y + 30.0 + float(track) * viewport_size.y * 0.045
		var spread := 20.0 + float(track) * 15.0
		_draw_ellipse_rect(Rect2(center_x - spread, y, 16.0, 8.0), Color(0.080, 0.045, 0.030, 0.38))
		_draw_ellipse_rect(Rect2(center_x + spread, y + 8.0, 16.0, 8.0), Color(0.080, 0.045, 0.030, 0.34))


func _draw_grass_layers(viewport_size: Vector2) -> void:
	for band in range(5):
		var y := viewport_size.y * (0.56 + float(band) * 0.085)
		var color := Color(0.105 + float(band) * 0.016, 0.205 + float(band) * 0.022, 0.105, 0.95)
		draw_rect(Rect2(0.0, y, viewport_size.x, viewport_size.y * 0.12), color)
	for tuft in range(90):
		var x := float((tuft * 73) % int(maxf(viewport_size.x, 1.0)))
		var y := viewport_size.y * 0.58 + float((tuft * 41) % int(maxf(viewport_size.y * 0.38, 1.0)))
		var height := 10.0 + float(tuft % 5) * 4.0
		draw_line(Vector2(x, y), Vector2(x + float(tuft % 7) - 3.0, y - height), Color(0.265, 0.410, 0.185, 0.58), 2.0)


func _draw_horse_shapes(viewport_size: Vector2) -> void:
	var base_y := viewport_size.y * 0.55
	for index in range(5):
		var x := viewport_size.x * (0.12 + float(index) * 0.18)
		var scale := 0.55 + float(index % 3) * 0.16
		var y := base_y + float(index % 2) * 38.0
		var alpha := 0.18 + float(index % 2) * 0.08
		_draw_horse_silhouette(Vector2(x, y), scale, Color(0.025, 0.018, 0.014, alpha))


func _draw_horse_silhouette(origin: Vector2, scale: float, color: Color) -> void:
	_draw_ellipse_rect(Rect2(origin.x - 52.0 * scale, origin.y - 20.0 * scale, 98.0 * scale, 34.0 * scale), color)
	draw_circle(origin + Vector2(58.0, -30.0) * scale, 18.0 * scale, color)
	draw_line(origin + Vector2(38.0, -18.0) * scale, origin + Vector2(54.0, -28.0) * scale, color, 14.0 * scale)
	for leg in [-34.0, -12.0, 18.0, 36.0]:
		draw_line(origin + Vector2(leg, 6.0) * scale, origin + Vector2(leg - 8.0, 48.0) * scale, color, 5.0 * scale)
	draw_line(origin + Vector2(-58.0, -12.0) * scale, origin + Vector2(-86.0, -34.0) * scale, color, 4.0 * scale)


func _draw_protagonist_silhouette(viewport_size: Vector2) -> void:
	var origin := Vector2(viewport_size.x * 0.50, viewport_size.y * 0.67)
	var scale := maxf(viewport_size.y / 720.0, 0.75)
	var shadow := Color(0.020, 0.014, 0.011, 0.86)
	_draw_ellipse_rect(Rect2(origin.x - 80.0 * scale, origin.y + 125.0 * scale, 160.0 * scale, 28.0 * scale), Color(0.0, 0.0, 0.0, 0.34))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-34, -132) * scale,
		origin + Vector2(34, -132) * scale,
		origin + Vector2(42, -24) * scale,
		origin + Vector2(22, 118) * scale,
		origin + Vector2(0, 148) * scale,
		origin + Vector2(-22, 118) * scale,
		origin + Vector2(-42, -24) * scale,
	]), Color(0.055, 0.027, 0.018, 0.96))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-20, -146) * scale,
		origin + Vector2(24, -144) * scale,
		origin + Vector2(38, -86) * scale,
		origin + Vector2(34, 76) * scale,
		origin + Vector2(0, 112) * scale,
		origin + Vector2(-32, 72) * scale,
		origin + Vector2(-38, -88) * scale,
	]), Color(0.105, 0.052, 0.028, 0.98))
	draw_circle(origin + Vector2(0.0, -138.0) * scale, 22.0 * scale, Color(0.100, 0.055, 0.038, 0.98))
	draw_line(origin + Vector2(26, -32) * scale, origin + Vector2(124, -50) * scale, shadow, 12.0 * scale)
	draw_line(origin + Vector2(104, -50) * scale, origin + Vector2(190, -50) * scale, Color(0.390, 0.375, 0.345, 0.92), 7.0 * scale)
	draw_line(origin + Vector2(-24, -26) * scale, origin + Vector2(-92, 26) * scale, shadow, 11.0 * scale)
	draw_line(origin + Vector2(-14, 94) * scale, origin + Vector2(-38, 168) * scale, shadow, 14.0 * scale)
	draw_line(origin + Vector2(14, 94) * scale, origin + Vector2(38, 168) * scale, shadow, 14.0 * scale)
	draw_line(origin + Vector2(-30, -98) * scale, origin + Vector2(18, -110) * scale, Color(0.610, 0.130, 0.085, 0.68), 5.0 * scale)


func _draw_vignette(viewport_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.0, 0.0, 0.16), false, 1.0)
	for ring in range(5):
		var inset := float(ring) * 18.0
		var alpha := 0.055 + float(ring) * 0.028
		draw_rect(Rect2(Vector2(inset, inset), viewport_size - Vector2(inset * 2.0, inset * 2.0)), Color(0.0, 0.0, 0.0, alpha), false, 22.0)


func _draw_ellipse_rect(rect: Rect2, color: Color, segments := 20) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var radius := rect.size * 0.5
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

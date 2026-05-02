class_name RpgTheme
extends RefCounted

const SURFACE_BASE := Color(0.055, 0.052, 0.047)
const SURFACE_PANEL := Color(0.105, 0.080, 0.060)
const SURFACE_ELEVATED := Color(0.145, 0.125, 0.100)
const TEXT_PRIMARY := Color(0.965, 0.910, 0.790)
const TEXT_SECONDARY := Color(0.745, 0.675, 0.555)
const ACCENT_DANGER := Color(0.650, 0.105, 0.075)
const ACCENT_PROGRESS := Color(0.760, 0.545, 0.265)
const ACCENT_MAP := Color(0.310, 0.555, 0.690)
const SUCCESS := Color(0.365, 0.610, 0.365)
const WARNING := Color(0.835, 0.555, 0.220)
const DISABLED := Color(0.355, 0.330, 0.295)


static func build_theme() -> Theme:
	var theme := Theme.new()

	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.74))
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", TEXT_PRIMARY.lightened(0.08))
	theme.set_color("font_pressed_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Button", TEXT_SECONDARY.darkened(0.28))
	theme.set_color("font_color", "CheckButton", TEXT_PRIMARY)
	theme.set_color("font_color", "LineEdit", TEXT_PRIMARY)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_SECONDARY)
	theme.set_color("font_color", "TextEdit", TEXT_PRIMARY)
	theme.set_color("font_color", "RichTextLabel", TEXT_PRIMARY)

	theme.set_constant("outline_size", "Label", 1)
	theme.set_constant("h_separation", "Button", 10)
	theme.set_font_size("font_size", "Label", 18)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_font_size("font_size", "CheckButton", 18)
	theme.set_font_size("font_size", "LineEdit", 18)

	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("normal", "Button", button_style(SURFACE_ELEVATED, ACCENT_PROGRESS.darkened(0.22)))
	theme.set_stylebox("hover", "Button", button_style(SURFACE_ELEVATED.lightened(0.08), ACCENT_PROGRESS))
	theme.set_stylebox("pressed", "Button", button_style(SURFACE_ELEVATED.darkened(0.08), ACCENT_DANGER.lightened(0.05)))
	theme.set_stylebox("focus", "Button", focus_style())
	theme.set_stylebox("disabled", "Button", button_style(DISABLED.darkened(0.20), DISABLED, 0.55))
	theme.set_stylebox("normal", "LineEdit", input_style(false))
	theme.set_stylebox("focus", "LineEdit", input_style(true))
	theme.set_stylebox("read_only", "LineEdit", input_style(false, true))
	theme.set_stylebox("normal", "TextEdit", input_style(false))
	theme.set_stylebox("focus", "TextEdit", input_style(true))

	return theme


static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(SURFACE_PANEL.r, SURFACE_PANEL.g, SURFACE_PANEL.b, 0.955)
	style.border_color = ACCENT_PROGRESS
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0.0, 6.0)
	return style


static func button_style(fill: Color, border: Color, alpha := 1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill.r, fill.g, fill.b, alpha)
	style.border_color = Color(border.r, border.g, border.b, alpha)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style


static func input_style(focused: bool, read_only := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill := SURFACE_ELEVATED.darkened(0.10) if not read_only else SURFACE_BASE.lightened(0.04)
	style.bg_color = Color(fill.r, fill.g, fill.b, 0.96)
	style.border_color = ACCENT_MAP if focused else Color(0.340, 0.275, 0.200)
	style.set_border_width_all(2 if focused else 1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ACCENT_MAP.r, ACCENT_MAP.g, ACCENT_MAP.b, 0.18)
	style.border_color = ACCENT_MAP.lightened(0.18)
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	return style

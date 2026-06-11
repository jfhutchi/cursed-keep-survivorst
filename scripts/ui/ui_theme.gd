class_name UiTheme
extends RefCounted
## Shared styling helpers for all UI screens: gothic dark panels with
## gold relic trim. Everything is built in code from StyleBoxFlat — no
## external theme assets needed.

const GOLD := Color(0.85, 0.71, 0.42)
const GOLD_DIM := Color(0.62, 0.52, 0.33)
const PARCHMENT := Color(0.91, 0.88, 0.82)
const BLOOD := Color(0.85, 0.25, 0.32)
const SOUL := Color(0.55, 0.83, 1.0)
const PANEL_BG := Color(0.075, 0.055, 0.115, 0.94)
const PANEL_BG_LIGHT := Color(0.12, 0.09, 0.18, 0.96)


static func panel_style(bg := PANEL_BG, border := GOLD_DIM, border_w := 2, radius := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(14)
	return style


static func make_button(text: String, font_size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 46)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", PARCHMENT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	var normal := panel_style(PANEL_BG_LIGHT, GOLD_DIM, 2, 6)
	normal.set_content_margin_all(8)
	var hover := panel_style(Color(0.17, 0.12, 0.26, 0.97), GOLD, 2, 6)
	hover.set_content_margin_all(8)
	var pressed := panel_style(Color(0.10, 0.07, 0.16, 0.97), GOLD, 3, 6)
	pressed.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	# visible focus ring so keyboard/controller navigation reads clearly
	var focus := panel_style(Color(0.17, 0.12, 0.26, 0.55), GOLD, 2, 6)
	focus.set_content_margin_all(8)
	b.add_theme_stylebox_override("focus", focus)
	b.focus_entered.connect(func() -> void: AudioManager.play(&"ui_hover", -8.0))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func() -> void: AudioManager.play(&"ui_click"))
	b.mouse_entered.connect(func() -> void: AudioManager.play(&"ui_hover", -8.0))
	return b


static func make_label(text: String, font_size := 16, color := PARCHMENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func make_title(text: String, font_size := 52, color := GOLD) -> Label:
	var l := make_label(text, font_size, color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l


static func make_bar(fill_color: Color, bg_color := Color(0.05, 0.04, 0.08, 0.85)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.set_corner_radius_all(4)
	bg.border_color = Color(0.3, 0.25, 0.4, 0.8)
	bg.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func dim_layer() -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	return dim

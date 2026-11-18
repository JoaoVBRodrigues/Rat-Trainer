class_name UIThemeResource
extends RefCounted

const PANEL_ASSET_ID: StringName = &"ui_panel"
const PANEL_ASSET_CATEGORY: StringName = &"ui"
const PANEL_SLICE_MARGIN: float = 16.0
const PANEL_CONTENT_MARGIN: float = 20.0


static func apply_runtime_assets(theme: Theme, assets: AssetResolver) -> bool:
	if theme == null:
		push_error("Cannot configure UI theme from a null resource.")
		return false
	if assets == null:
		push_error("Cannot configure UI theme without an asset resolver.")
		return false

	var panel_texture: Texture2D = assets.get_texture(PANEL_ASSET_ID, PANEL_ASSET_CATEGORY)
	if panel_texture == null:
		push_error("Could not resolve the shared UI panel texture.")
		return false

	var panel_style: StyleBoxTexture = StyleBoxTexture.new()
	panel_style.texture = panel_texture
	panel_style.texture_margin_left = PANEL_SLICE_MARGIN
	panel_style.texture_margin_top = PANEL_SLICE_MARGIN
	panel_style.texture_margin_right = PANEL_SLICE_MARGIN
	panel_style.texture_margin_bottom = PANEL_SLICE_MARGIN
	panel_style.content_margin_left = PANEL_CONTENT_MARGIN
	panel_style.content_margin_top = PANEL_CONTENT_MARGIN
	panel_style.content_margin_right = PANEL_CONTENT_MARGIN
	panel_style.content_margin_bottom = PANEL_CONTENT_MARGIN
	panel_style.modulate_color = theme.get_color("panel_tint", "UITheme")
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	return true

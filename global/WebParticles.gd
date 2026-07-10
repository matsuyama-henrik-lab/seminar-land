class_name WebParticles
# ウェブ書き出し用のパーティクル変換 / Particle conversion for web export.
# 一部のスマホのブラウザは GPUParticles2D を動かせないので、表示前に
# CPUParticles2D に自動で置き換えます。ふだん気にする必要はありません。
# Some phone browsers can't run GPUParticles2D, so this swaps them for
# CPUParticles2D before a level is shown. You normally don't need to touch this.

# Helpers for making GPUParticles2D work on web export.
#
# Some mobile browsers can't run GPUParticles2D (no compute support), so we swap
# them for CPUParticles2D equivalents before a level is shown. Pure functions:
# they only transform the node/material passed in, so they live here as static
# utilities rather than on World.


# Walk the tree under `node` and replace every GPUParticles2D with an equivalent
# CPUParticles2D. Call this while the tree is detached so the GPU nodes never get
# a chance to render a broken frame.
static func convert(node: Node) -> void:
	# Copy the child list first: we mutate the tree while iterating.
	# Qualify the recursion: bare convert() would resolve to GDScript's built-in
	# convert(value, type) instead of this method.
	for child in node.get_children():
		WebParticles.convert(child)
	if node is GPUParticles2D:
		var cpu := CPUParticles2D.new()
		cpu.convert_from_particles(node)
		# convert_from_particles() handles velocity/accel/scale curves, but a few
		# ParticleProcessMaterial features have no direct CPU equivalent and get
		# dropped. Patch the ones students actually use back in by hand.
		var mat = node.process_material
		if mat is ParticleProcessMaterial:
			# Hue variation behaves differently than on the GPU; reproduce it.
			_apply_hue_variation(cpu, mat)
			# CPUParticles2D has no separate alpha curve; alpha-over-lifetime must
			# live in its color_ramp, so bake the material's alpha_curve into it.
			_bake_alpha_curve(cpu, mat)
		cpu.name = node.name
		cpu.transform = node.transform
		cpu.z_index = node.z_index
		cpu.z_as_relative = node.z_as_relative
		cpu.visible = node.visible
		cpu.emitting = node.emitting
		var parent := node.get_parent()
		var idx := node.get_index()
		parent.remove_child(node)
		node.queue_free()
		parent.add_child(cpu)
		parent.move_child(cpu, idx)

# GPUParticles2D's hue_variation visibly tints even a white particle: it spreads
# the particles across a band of hues (e.g. 0.18-0.24 ~ yellows). CPUParticles2D's
# hue rotation is luminance-preserving, so it leaves a white particle white and
# copying hue_variation across does nothing. Reproduce the GPU look by turning the
# hue range into per-particle spawn colours via color_initial_ramp, and disable the
# CPU hue rotation so it isn't applied on top.
static func _apply_hue_variation(cpu: CPUParticles2D, mat: ParticleProcessMaterial) -> void:
	var h_min: float = mat.hue_variation_min
	var h_max: float = mat.hue_variation_max
	if h_min == 0.0 and h_max == 0.0:
		return
	# The GPU's hue_variation is a rotation from a warmer reference, not an absolute
	# HSV hue, so mapping the raw value straight to HSV lands ~0.06 too far toward
	# green. Shift the band back to match the GPU's yellow. Nudge this if the tint is
	# still off (more negative = warmer/redder, less = greener).
	const HUE_OFFSET := -0.06
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	# Full saturation/value so the band reads as colour against the white texture;
	# tune the s/v here if the result looks too vivid next to the GPU build.
	grad.colors = PackedColorArray([
		Color.from_hsv(fposmod(h_min + HUE_OFFSET, 1.0), 1.0, 1.0),
		Color.from_hsv(fposmod(h_max + HUE_OFFSET, 1.0), 1.0, 1.0),
	])
	cpu.color_initial_ramp = grad
	cpu.hue_variation_min = 0.0
	cpu.hue_variation_max = 0.0

# Folds a ParticleProcessMaterial.alpha_curve (alpha over lifetime) into the
# CPUParticles2D color_ramp, since CPUParticles2D has no standalone alpha curve.
# Any RGB color ramp convert_from_particles() already produced is preserved; we
# only override the alpha channel.
static func _bake_alpha_curve(cpu: CPUParticles2D, mat: ParticleProcessMaterial) -> void:
	var alpha_tex := mat.alpha_curve as CurveTexture
	if alpha_tex == null or alpha_tex.curve == null:
		return
	var alpha_curve: Curve = alpha_tex.curve
	# RGB comes from the converted color ramp if there was one; otherwise white,
	# so the per-particle tint stays in cpu.color (which the engine multiplies in)
	# rather than getting applied twice.
	var rgb_ramp: Gradient = cpu.color_ramp  # from convert_from_particles(); may be null
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	var steps := 16
	for i in range(steps + 1):
		var t := float(i) / steps
		var col: Color = rgb_ramp.sample(t) if rgb_ramp != null else Color.WHITE
		col.a = alpha_curve.sample(t)
		offsets.append(t)
		colors.append(col)
	var grad := Gradient.new()
	grad.offsets = offsets
	grad.colors = colors
	cpu.color_ramp = grad

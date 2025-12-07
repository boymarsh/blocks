shader_type canvas_item;

uniform vec4 base_color   : source_color = vec4(0.05, 0.07, 0.15, 1.0); // dark blue
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);    // black
uniform float border_thickness = 0.06; // 6% of tile

void fragment() {
    // Distance to nearest edge in UV space (0..1 per tile)
    float d = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));

    // 1.0 in border region, 0.0 in interior
    float border = step(d, border_thickness);

    // Solid blue interior, black border
    COLOR = mix(base_color, border_color, border);
}

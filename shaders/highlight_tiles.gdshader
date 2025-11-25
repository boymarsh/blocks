shader_type canvas_item;

// overall alpha of the highlight
uniform float alpha_mult : hint_range(0.0, 1.0) = 0.6;

// colour tint for the inside of the block
uniform vec4 inner_tint : source_color = vec4(1.1, 1.1, 1.1, 1.0);

// colour for the outline (values > 1.0 will glow with bloom)
uniform vec4 outline_color : source_color = vec4(2.0, 1.6, 2.0, 1.0);

// outline in pixels
uniform float outline_size : hint_range(0.0, 4.0) = 1.0;

// 1.0 = normal saturation, >1 = more saturated
uniform float saturation_boost : hint_range(0.0, 2.0) = 1.4;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float a = tex.a;

    // --- detect outline by sampling neighbours ---
    float outline = 0.0;
    vec2 off = TEXTURE_PIXEL_SIZE * outline_size;

    outline += texture(TEXTURE, UV + vec2( off.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(-off.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0,  off.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -off.y)).a;

    vec4 out_color = vec4(0.0);

    // transparent pixel but next to solid -> outline
    if (a < 0.1 && outline > 0.0) {
        out_color = vec4(outline_color.rgb, outline_color.a * alpha_mult);
    }
    // inside the tile: saturated ghost
    else if (a > 0.1) {
        vec3 col = tex.rgb * inner_tint.rgb;

        // cheap saturation boost
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        col = mix(vec3(luma), col, saturation_boost);

        out_color = vec4(col, a * alpha_mult);
    }

    COLOR = out_color;
}

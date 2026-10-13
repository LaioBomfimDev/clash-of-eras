shader_type canvas_item;
// Escala não inteira de pixel art (ex.: 1,2× e 1,44× dos níveis na partida).
// Dentro de cada texel usa a cor exata; só a borda entre texels mistura 1 pixel de tela.
// A 1× com posição inteira o resultado é idêntico ao filtro nearest.
// Requer filtro linear no CanvasItem que usa este material.

void fragment() {
	vec2 texture_size = vec2(textureSize(TEXTURE, 0));
	vec2 texel = UV * texture_size;
	vec2 seam = floor(texel + 0.5);
	vec2 texel_per_pixel = max(fwidth(texel), vec2(0.0001));
	texel = seam + clamp((texel - seam) / texel_per_pixel, -0.5, 0.5);
	COLOR = texture(TEXTURE, texel / texture_size) * COLOR;
}

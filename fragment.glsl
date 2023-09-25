#version 330 core
out vec4 FragColor;

in vec2 tex_coord;

uniform sampler2D gui_texture;
uniform sampler2D img_texture;

void main() {
	vec4 gui_clr = texture(gui_texture, tex_coord);
	vec4 img_clr = texture(img_texture, tex_coord);
//	FragColor = mix(gui_clr, img_clr, img_clr.w);
	FragColor = vec4((1.0 - gui_clr.w)*img_clr + (gui_clr.w * gui_clr));
//	FragColor = gui_clr;
};

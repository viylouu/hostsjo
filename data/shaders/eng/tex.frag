#version 330 core

uniform sampler2D tex;
uniform vec2 samp_pos;
uniform vec2 samp_size;
uniform vec4 tint;

in vec2 uvs;

out vec4 fCol;

void main() {
	fCol = texture(tex, uvs * samp_size + samp_pos) * tint;
}

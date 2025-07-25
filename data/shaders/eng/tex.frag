#version 330 core

uniform sampler2D tex;
uniform vec2 samp_pos;
uniform vec2 samp_size;
uniform vec4 tint;

in vec2 uvs;

out vec4 fCol;

void main() {
	vec4 col = texture(tex, uvs * samp_size + samp_pos) * tint;
    if (col.a == 0) {
        discard;
    }
    fCol = col;
}

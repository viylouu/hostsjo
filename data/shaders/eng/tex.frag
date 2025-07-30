#version 330 core

uniform sampler2D tex;

flat in vec2 samp_pos;
flat in vec2 samp_size;
flat in vec4 col;
in vec2 uvs;

out vec4 frag_col;

void main() {
	vec4 dat = texture(tex, uvs * samp_size + samp_pos) * col;
    if (dat.a == 0) {
        discard;
    }
    frag_col = dat;
}

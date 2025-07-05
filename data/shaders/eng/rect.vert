#version 330 core

layout(location = 0)in vec2 vPos;

uniform mat4 proj;
uniform vec2 pos;
uniform vec2 size;

void main() {
	gl_Position = proj * vec4(vPos * size + pos, 0, 1);
}

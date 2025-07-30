#version 330 core

flat in vec4 col;

out vec4 frag_col;

void main() {
    frag_col = col;
}

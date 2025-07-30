#version 430 core

struct Instance_Data {
    mat4 trans;
    vec2 pos;
    vec2 size;
    vec2 samp_pos;
    vec2 samp_size;
    vec4 col;
};

layout(std140, binding = 0) buffer batchSSBO {
    Instance_Data insts[];
};

uniform mat4 proj;

const vec2 verts[6] = vec2[6](
            vec2(0,0), vec2(1,0),
            vec2(1,1), vec2(1,1),
            vec2(0,1), vec2(0,0)
        );

flat out vec2 samp_pos;
flat out vec2 samp_size;
flat out vec4 col;
out vec2 uvs;

void main() {
    vec2 vert = verts[gl_VertexID % 6];
    Instance_Data data = insts[gl_VertexID / 6];

	gl_Position = proj * data.trans * vec4(vert * data.size + data.pos, 0, 1);

    samp_pos = data.samp_pos;
    samp_size = data.samp_size;
    col = data.col;
    uvs = vert;
}

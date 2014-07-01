#version 300 es

#define PASS1_ATTRIB_POSITION  0
#define PASS1_ATTRIB_TEXCOORD  1

layout (location = PASS1_ATTRIB_POSITION) in vec3 in_position;
layout (location = PASS1_ATTRIB_TEXCOORD) in vec2 in_texcoord;

out mediump vec2 v_texcoord;

void main(void) {
    v_texcoord  = in_texcoord;
    gl_Position = vec4(in_position, 1.0);
}

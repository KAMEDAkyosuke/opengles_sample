#version 300 es

#define PASS0_ATTRIB_POSITION  0
#define PASS0_ATTRIB_COLOR     1

layout (location = PASS0_ATTRIB_POSITION)  in vec3 in_position;
layout (location = PASS0_ATTRIB_COLOR)     in vec4 in_color;

out lowp vec4 v_color;

void main(void) {
    v_color     = in_color;
    gl_Position = vec4(in_position, 1.0);
}

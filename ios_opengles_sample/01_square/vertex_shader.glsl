#version 300 es

#define ATTRIB_POSITION  0
#define ATTRIB_COLOR     1

layout (location = ATTRIB_POSITION)  in vec3 in_position;
layout (location = ATTRIB_COLOR)     in vec4 in_color;

out lowp vec4 v_color;

void main(void) {
    v_color     = in_color;
    gl_Position = vec4(in_position, 1.0);
}

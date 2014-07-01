#version 300 es

#define ATTRIB_POSITION  0
#define ATTRIB_COLOR     1

layout (location = ATTRIB_POSITION)  in vec3 in_position;
layout (location = ATTRIB_COLOR)     in vec4 in_color;

out lowp vec4 v_color;

uniform mat4 projection;
uniform mat4 cameraview;
uniform mat4 modeltrans;
uniform mat4 modelrotate;

void main(void) {
    v_color     = in_color;
    gl_Position = projection * cameraview * modeltrans * modelrotate * vec4(in_position, 1.0);
}

#version 300 es

#define PASS0_ATTRIB_POSITION  0
#define PASS0_ATTRIB_COLOR     1
#define PASS0_ATTRIB_NORMAL    2

layout (location = PASS0_ATTRIB_POSITION)  in vec3 in_position;
layout (location = PASS0_ATTRIB_COLOR)     in vec4 in_color;
layout (location = PASS0_ATTRIB_NORMAL)    in vec3 in_normal;

out lowp float v_depth;
out lowp vec3  v_normal;

uniform mat4 projection;
uniform mat4 cameraview;
uniform mat4 modeltrans;
uniform mat4 modelrotate;

const vec3 main_light = normalize(vec3( 1.0, 1.0, 1.0));
const vec3 sub_light  = normalize(vec3(-1.0,-1.0,-1.0));

void main(void) {
    v_normal = normalize(vec3(modelrotate * vec4(in_normal, 1.0)));
    gl_Position = projection * cameraview * modeltrans * modelrotate * vec4(in_position, 1.0);
    v_depth  = ((gl_Position.z / gl_Position.w) + 1.0) / 2.0;
}

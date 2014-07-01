#version 300 es

#define PASS1_ATTRIB_POSITION  0
#define PASS1_ATTRIB_COLOR     1
#define PASS1_ATTRIB_NORMAL    2

layout (location = PASS1_ATTRIB_POSITION)  in vec3 in_position;
layout (location = PASS1_ATTRIB_COLOR)     in vec4 in_color;
layout (location = PASS1_ATTRIB_NORMAL)    in vec3 in_normal;

out lowp vec4 v_color;

uniform mat4 projection;
uniform mat4 cameraview;
uniform mat4 modeltrans;
uniform mat4 modelrotate;

const vec3 main_light = normalize(vec3( 1.0, 1.0, 1.0));
const vec3 sub_light  = normalize(vec3(-1.0,-1.0,-1.0));

void main(void) {
    vec3 nnormal = normalize(vec3(modelrotate * vec4(in_normal, 1.0)));
    
    float main_diff = max(dot(nnormal, main_light), 0.0) * 1.0;
    float sub_diff  = max(dot(nnormal, sub_light),  0.0) * 0.3;
    
    float diff = min(1.0, main_diff + sub_diff);
    v_color     = in_color * diff;
    gl_Position = projection * cameraview * modeltrans * modelrotate * vec4(in_position, 1.0);
}

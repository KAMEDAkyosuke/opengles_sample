#version 300 es

in lowp vec4 v_color;
in lowp vec3 v_normal;

layout (location = 0) out mediump vec4 color;

void main()
{
    color = v_color;
}

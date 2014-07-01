#version 300 es

in lowp vec4 v_color;

layout (location = 0) out mediump vec4 color;

void main()
{
    color = v_color;
}

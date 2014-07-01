#version 300 es

in lowp float v_depth;
in lowp vec3  v_normal;

layout (location = 0) out mediump vec4 color;

void main()
{
    color = vec4(v_normal.r, v_normal.g, v_normal.b, v_depth);
}

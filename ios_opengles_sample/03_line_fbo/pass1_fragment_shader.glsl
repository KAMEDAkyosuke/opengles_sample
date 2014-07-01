#version 300 es

in lowp vec2 v_texcoord;

layout (location = 0) out mediump vec4 color;

uniform sampler2D tex;

void main()
{
    color = texture(tex, v_texcoord) * 2.0f;
}

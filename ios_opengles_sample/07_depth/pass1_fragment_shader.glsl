#version 300 es

in lowp vec2 v_texcoord;

layout (location = 0) out mediump vec4 color;

uniform sampler2D tex;

void main()
{
    highp vec4 t = texture(tex, v_texcoord);
    color = vec4(t.w, t.w, t.w, 1.0);
}

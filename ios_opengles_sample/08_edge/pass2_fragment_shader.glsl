#version 300 es

in mediump vec2 v_texcoord;

layout (location = 0) out mediump vec4 color;

uniform mediump sampler2D edge_tex;
uniform mediump sampler2D color_tex;

void main()
{
    // 水平方向
    mediump vec4 h0 = textureOffset(edge_tex, v_texcoord, ivec2(-1, 1)) * -1.0;
    mediump vec4 h1 = textureOffset(edge_tex, v_texcoord, ivec2(-1, 0)) * -2.0;
    mediump vec4 h2 = textureOffset(edge_tex, v_texcoord, ivec2(-1, -1)) * -1.0;
    mediump vec4 h3 = textureOffset(edge_tex, v_texcoord, ivec2(1, 1)) * 1.0;
    mediump vec4 h4 = textureOffset(edge_tex, v_texcoord, ivec2(1, 0)) * 2.0;
    mediump vec4 h5 = textureOffset(edge_tex, v_texcoord, ivec2(1, -1)) * 1.0;
    mediump vec4 h = h0 + h1 + h2 + h3 + h4 + h5;
    
    // 垂直方向
    mediump vec4 v0 = textureOffset(edge_tex, v_texcoord, ivec2(-1, 1)) * -1.0;
    mediump vec4 v1 = textureOffset(edge_tex, v_texcoord, ivec2(0, 1)) * -2.0;
    mediump vec4 v2 = textureOffset(edge_tex, v_texcoord, ivec2(1, 1)) * -1.0;
    mediump vec4 v3 = textureOffset(edge_tex, v_texcoord, ivec2(-1, -1)) * 1.0;
    mediump vec4 v4 = textureOffset(edge_tex, v_texcoord, ivec2(0, -1)) * 2.0;
    mediump vec4 v5 = textureOffset(edge_tex, v_texcoord, ivec2(1, -1)) * 1.0;
    mediump vec4 v = v0 + v1 + v2 + v3 + v4 + v5;
    
    mediump float edge = sqrt(dot(h,h) + dot(v,v));
    edge  = step(edge, 0.9);
    color = texture(color_tex, v_texcoord) * edge;
}

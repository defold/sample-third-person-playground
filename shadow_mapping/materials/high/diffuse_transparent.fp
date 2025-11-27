#version 140

in highp vec4 var_position;
in highp vec3 var_normal;
in highp vec2 var_texcoord0;
in highp vec4 var_texcoord0_shadow;
in highp vec4 var_light;

out vec4 out_fragColor;

uniform highp sampler2D tex0;
uniform highp sampler2D tex_depth;

uniform fs_uniforms
{
    uniform highp vec4 intensity;
};

#include "/shadow_mapping/materials/high/shadows_high.glsl"

void main()
{
    vec4 color = texture(tex0, var_texcoord0.xy);

    // Diffuse light calculations.
    vec3 ambient_light = vec3(0.4);
    vec3 diff_light    = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light         = max(dot(var_normal,1.0 - diff_light), 0.0) + ambient_light;
    diff_light         = clamp(diff_light, 0.6, 1.0);

    vec4 depth_proj    = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow_value = shadow_calculation(depth_proj.xyz);
    out_fragColor = vec4(intensity.r, intensity.g, intensity.b, intensity.w * (1.0 - shadow_value)) * color.w;
}


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
    uniform highp vec4 ambient_light;
};

#include "/shadow_mapping/materials/high/shadows_high.glsl"

void main()
{
    vec4 color = texture(tex0, var_texcoord0.xy);
    
    // Diffuse light calculations.
    vec3 diff_light    = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light         = max(dot(var_normal,diff_light), 0.0) + ambient_light.xyz;
    diff_light         = clamp(diff_light, 0.6, 1.0);

    // Influence the shadows based on the angle between the surface normal and the direction of the light
    // The more orthogonal they are the more perspective artifacts we'll have. It's not exactly physically correct,
    // but it's better than nothing!
    // float n_to_l_angle = clamp(dot(var_normal, var_light.xyz), 0.0, 1.0);
    vec4 depth_proj    = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow_value = shadow_calculation(depth_proj.xyz);
    vec3 color_out     = color.rgb * diff_light;
    color_out          = mix(color_out * 0.75, color_out, shadow_value);
    out_fragColor      = vec4(color_out,1.0) * color.w;
}


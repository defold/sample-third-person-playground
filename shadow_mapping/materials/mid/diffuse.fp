#version 140

in highp vec4 var_position;
in highp vec3 var_normal;
in highp vec2 var_texcoord0;
in highp vec4 var_texcoord0_shadow;
in highp vec4 var_light;

out vec4 out_fragColor;

uniform highp sampler2D tex0;

// #include "/shadow_mapping/materials/mid/shadows_mid.glsl"

void main()
{
    vec4 color = texture(tex0, var_texcoord0.xy);
    
    // Diffuse light calculations.
    vec3 ambient_light = vec3(0.3);
    vec3 diff_light    = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light         = max(dot(var_normal,diff_light), 0.0) + ambient_light;
    diff_light         = clamp(diff_light, 0.6, 1.0);

    vec3 color_out     = color.rgb * diff_light;
    out_fragColor      = vec4(color_out,1.0) * color.w;
}

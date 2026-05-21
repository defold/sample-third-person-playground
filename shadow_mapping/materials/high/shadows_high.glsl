#define SHADOW_MAP_WIDTH  2048.0
#define SHADOW_MAP_HEIGHT 2048.0

float rgba_to_float(vec4 rgba)
{
	return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

float sample_shadow(vec3 depth_data, vec2 offset, vec2 texel_size, float depth_bias)
{
	float depth = rgba_to_float(texture(tex_depth, depth_data.st + offset * texel_size));
	return (depth_data.z - depth_bias > depth) ? 0.0 : 1.0;
}

float shadow_calculation(vec3 depth_data)
{
	const float depth_bias = 0.0005;
	vec2 texel_size        = 1.0 / vec2(SHADOW_MAP_WIDTH, SHADOW_MAP_HEIGHT);

	float shadow = 0.0;

	shadow += sample_shadow(depth_data, vec2(-1.0, -1.0), texel_size, depth_bias);
	shadow += sample_shadow(depth_data, vec2( 0.0, -1.0), texel_size, depth_bias);
	shadow += sample_shadow(depth_data, vec2( 1.0, -1.0), texel_size, depth_bias);

	shadow += sample_shadow(depth_data, vec2(-1.0,  0.0), texel_size, depth_bias);
	shadow += sample_shadow(depth_data, vec2( 0.0,  0.0), texel_size, depth_bias);
	shadow += sample_shadow(depth_data, vec2( 1.0,  0.0), texel_size, depth_bias);

	shadow += sample_shadow(depth_data, vec2(-1.0,  1.0), texel_size, depth_bias);
	shadow += sample_shadow(depth_data, vec2( 0.0,  1.0), texel_size, depth_bias);
	shadow += sample_shadow(depth_data, vec2( 1.0,  1.0), texel_size, depth_bias);

	return shadow / 9.0;
}

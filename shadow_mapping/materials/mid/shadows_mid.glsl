
// #define SHADOW_MAP_WIDTH  512.0
// #define SHADOW_MAP_HEIGHT 512.0

float rgba_to_float(vec4 rgba)
{
	return dot(rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0));
}

float shadow_calculation(vec3 depth_data)
{
	const float depth_bias = 0.0005;
	float depth            = rgba_to_float(texture(tex_depth, depth_data.st));
	float shadow           = depth_data.z - depth_bias > depth ? 0.0 : 1.0;
	return shadow;
}

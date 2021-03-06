#include "global.fx"

#define MAX_NUMBER_LIGHT_IN_WORLD 255

#define SPOT_LIGHT_TYPE 0
#define POINT_LIGHT_TYPE 1
#define DIRECTIONAL_LIGHT_TYPE 2

struct Light {
	float4 position;
	float4 direction;
	float4 color;
	int light_type;
	float radius;
	float range;
	float pad;
};

struct Material {
	float4 ambient;
	float4 diffuse;
	float4 specular;
};

cbuffer ambient_constant {
	float3 ambient_lower_color;
	float3 ambient_upper_color;
	int light_count;
	int light_model_index;
	Material material;
	Light lights[MAX_NUMBER_LIGHT_IN_WORLD];
};


float4 calculate_ambient_light(float3 normal, float3 color)
{
	float up = normal.y * 0.5 + 0.5;
	float3 ambient_color = ambient_lower_color + up * ambient_upper_color;
	return float4(ambient_color * color, 0.0f);
}

float4 calculate_spot_light(Light light, Material material, float3 normal, float3 position)
{
	float shininess = material.specular.w;

	float4 diffuse = { 0.0f, 0.0f, 0.0f, 0.0f };
	float4 specular = { 0.0f, 0.0f, 0.0f, 0.0f };

	float ambient_power = 0.1f;
	float4 ambient = ambient_power * material.ambient * light.color;
	//float4 ambient = calculate_ambient_light(normal, light.color);

	float3 to_light = normalize(light.position - position);

	float theta = dot(-to_light, light.direction);
	float x = cos(radians(light.radius));
	if (theta > x) {
		return float4(0.0f, 0.0f, 0.0f, 0.0f);
	}

	normal = normalize(normal);

	float diffuse_factor = max(dot(-light.direction, normal), 0.0f);

	if (diffuse_factor > 0.0f) {
		float3 reflect_dir = normalize(reflect(light.direction, normal));
		float3 dir_to_camera = normalize(camera_position - position);
		
		float specular_factor = pow(max(dot(reflect_dir, dir_to_camera), 0.0f), shininess);
		
		diffuse = diffuse_factor * material.diffuse * light.color;
		specular = specular_factor * material.specular * light.color;
	}

	return specular + diffuse + ambient;
}

float4 calculate_point_light(Light light, Material material, float3 normal, float3 world_position)
{
	float shininess = material.specular.w;
	float distance = length(light.position - world_position);

	if (distance > light.range)
		return float4(0.0f, 0.0f, 0.0f, 0.0f);
	
	float3 to_light = normalize((float3)light.position - world_position);

	float4 diffuse = { 0.0f, 0.0f, 0.0f, 0.0f };
	float4 specular = { 0.0f, 0.0f, 0.0f, 0.0f };

	float ambient_power = 0.1f;
	float4 ambient = ambient_power * material.ambient * light.color;
	//float4 ambient = calculate_ambient_light(normal, light.color);

	normal = normalize(normal);

	float diffuse_factor = max(dot(to_light, normal), 0.0f);

	if (diffuse_factor > 0.0f) {

		float3 reflect_dir = normalize(reflect(-to_light, normal));

		float3 dir_to_camera = normalize(camera_position - world_position);
		float specular_factor = pow(max(dot(reflect_dir, dir_to_camera), 0.0f), shininess);
		
		diffuse = diffuse_factor * material.diffuse * light.color;
		specular = specular_factor * material.specular * light.color;

		float x = 1.0f - saturate(distance * ( 1.0f / light.range));
		float attenuation = x * x;

		ambient *= attenuation;
		diffuse *= attenuation;
		specular *= attenuation;
	}

	return specular + diffuse + ambient;
}

float4 calculate_directional_light(Light light, Material material, float3 normal, float3 world_position)
{
	float shininess = material.specular.w;

	float4 diffuse = { 0.0f, 0.0f, 0.0f, 0.0f };
	float4 specular = { 0.0f, 0.0f, 0.0f, 0.0f };

	float ambient_power = 0.1f;
	float4 ambient = ambient_power * material.ambient * light.color;
	//float4 ambient = calculate_ambient_light(normal, light.color);

	normal = normalize(normal);

	float diffuse_factor = max(dot(-light.direction, normal), 0.0f);

	if (diffuse_factor > 0.0f) {
		diffuse = diffuse_factor * material.diffuse * light.color;

		float3 reflect_dir = normalize(reflect(light.direction, normal));

		float3 dir_to_camera = normalize(camera_position - world_position);
		float specular_factor = pow(max(dot(reflect_dir, dir_to_camera), 0.0f), shininess);
		specular = specular_factor * material.specular * light.color;
	}

	return specular + diffuse + ambient;
}


struct Vertex_In {
	float3 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD;
};

struct Vertex_Out {
	float4 position : SV_POSITION;
	float3 world_position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD;
};

Vertex_Out vs_main(Vertex_In vertex)
{
	Vertex_Out result;
	result.position = mul(float4(vertex.position, 1.0f), world_view_projection);
	result.world_position = mul(float4(vertex.position, 1.0f), world);
	result.normal = mul(vertex.normal, (float3x3)world);
	result.uv = vertex.uv;
	return result;
}

float4 ps_main(Vertex_Out pixel, uniform bool use_texture) : SV_Target
{
	float4 texture_color;
	if (use_texture) {
		texture_color = texture_map.Sample(sampler_anisotropic, pixel.uv);
	} else {
		texture_color = float4(model_color, 1.0f);
	}

	float4 final_color = { 0.0f, 0.0f, 0.0f, 0.0f };
	for (int i = 0; i < light_count; i++) {
		switch (lights[i].light_type) {
			case SPOT_LIGHT_TYPE:
				final_color += calculate_spot_light(lights[i], material, pixel.normal, pixel.world_position);
				break;
			case POINT_LIGHT_TYPE:
				final_color += calculate_point_light(lights[i], material, pixel.normal, pixel.world_position);
				break;
			case DIRECTIONAL_LIGHT_TYPE:
				final_color += calculate_directional_light(lights[i], material, pixel.normal, pixel.world_position);
				break;
		}
	}

	float4 r = final_color * texture_color;
	r.a = material.diffuse.a * texture_color.a;
	return r;
}

float4 ps_render_light_model(Vertex_Out pixel) : SV_Target
{
	return lights[light_model_index].color;
}

technique11 render_model_use_texture {
	pass P0 {
		SetVertexShader(CompileShader(vs_5_0, vs_main()));
		SetPixelShader(CompileShader(ps_5_0, ps_main(true)));
	}
}

technique11 render_model_use_color {
	pass P0 {
		SetVertexShader(CompileShader(vs_5_0, vs_main()));
		SetPixelShader(CompileShader(ps_5_0, ps_main(false)));
	}
}

technique11 render_light_model {
	pass P0 {
		SetVertexShader(CompileShader(vs_5_0, vs_main()));
		SetPixelShader(CompileShader(ps_5_0, ps_render_light_model()));
	}
}
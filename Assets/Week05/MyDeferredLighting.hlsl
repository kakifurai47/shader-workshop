#ifndef MY_DEFERRED_LIGHTING_INCLUDED
#define MY_DEFERRED_LIGHTING_INCLUDED

#define M_EPSILON 1

struct MySurfaceData {
	float3 position;
	float  shininess;
	float3 normal;
	float  pad0;
};

float4 GetPointLightShading(MySurfaceData surface, MyPointLight light) {
	float3 d = light.position - surface.position;
	float3 N = normalize(surface.normal);
	float3 L = normalize(d);
	float3 V = normalize(light.position - _WorldSpaceCameraPos);

	float  cosine = max(0, dot(N, L));
	float3 R = N - 2.0 * L * cosine;

	float4 diffuse  = cosine;
	float4 specular = pow(max(0, dot(R, V)), surface.shininess);

	float d2 = dot(d, d);
	float attenuation = 1 / (d2 + M_EPSILON);
	float range2 = light.range * light.range;

	float4 o = 0;
	o += diffuse;
	o += specular;
	o *= attenuation;
	o *= light.intensity;
	o *= float4(light.color, 1);
	o *= step(d2, range2);
	return o;
}

float4 GetSpotLightShading(MySurfaceData surface, MySpotLight light) {
	float3 L = normalize(light.position - surface.position);
	float t = saturate((dot(light.direction, L) - light.cosOuter) * light.invAngDif);
	return GetPointLightShading(surface, MyPointLightConstructor(light)) * t * t;
}

#endif
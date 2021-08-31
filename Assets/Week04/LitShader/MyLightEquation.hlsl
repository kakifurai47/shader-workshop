#ifndef MY_LIGHT_EQUATION_INCLUDED
#define MY_LIGHT_EQUATION_INCLUDED

#define M_EPSILON 1

float4 GetPointLightShading(float3 posWS, float3 normWS, MyPointLight light) {
	float3 d = light.position - posWS;
	float3 N = normalize(normWS);
	float3 L = normalize(d);
	float3 V = normalize(light.position - _WorldSpaceCameraPos);
	
	float  cosine = max(0, dot(N, L));
	float3 R      = N - 2.0 * L * cosine;	

	float4 diffuse	= _DiffuseColor * cosine;
	float4 specular	= _SpecularColor * pow(max(0, dot(R, V)), _Shininess);

	float d2		  = dot(d, d);
	float attenuation = 1 / (d2 + M_EPSILON);
	float range2      = light.range * light.range;

	float4 o = 0;
	o += diffuse;
	o += specular;
	o *= attenuation;
	o *= light.intensity;
	o *= float4(light.color, 1);
	o *= step(d2, range2);
	return o;
}

float4 GetSpotLightShading(float3 posWS, float3 normWS, MySpotLight light) {
	float3 d = light.position - posWS;
	float3 N = normalize(normWS);
	float3 L = normalize(d);
	float3 V = normalize(light.position - _WorldSpaceCameraPos);

	float  cosine = max(0, dot(N, L));
	float3 R = N - 2.0 * L * cosine;

	float4 diffuse  = _DiffuseColor * cosine;
	float4 specular = _SpecularColor * pow(max(0, dot(R, V)), _Shininess);

	float d2		  = dot(d, d);
	float t			  = saturate((dot(light.direction, L) - light.cosOuter) * light.invAngDif);
	float attenuation = t * t / (d2 + M_EPSILON);;
	float range2	  = light.range * light.range;

	float4 o = 0;
	o += diffuse;
	o += specular;
	o *= attenuation;
	o *= light.intensity;
	o *= float4(light.color, 1);
	o *= step(d2, range2);
	return o;
}



#endif
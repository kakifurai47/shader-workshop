#ifndef MY_LIGHT_COMMON_INCLUDED
#define MY_LIGHT_COMMON_INCLUDED

#define MAX_DIR_LIGHT   8
#define MAX_POINT_LIGHT 8
#define MAX_SPOT_LIGHT  8

struct MyPointLight {
	float3 position;
	float  range;
	float3 color;
	float  intensity;
};

struct MySpotLight {
	float3 position;
	float  range;
	float3 direction;
	float  intensity;	
	float3 color;
	float  cosOuter;
	float  invAngDif;
	float3 pad0;
};

CBUFFER_START(MyLightBuffer)
uniform float4 my_pointLightBuf[MAX_DIR_LIGHT * 2];
uniform float4 my_spotLightBuf[MAX_DIR_LIGHT  * 4];
uniform float  my_pointLightSize;
uniform float  my_spotLightSize;
CBUFFER_END

MyPointLight GetMyPointLight(int idx) {	
	float i = idx * 2;
	float4 offset0 = my_pointLightBuf[i + 0];
	float4 offset1 = my_pointLightBuf[i + 1];

	MyPointLight l;
	l.position  = offset0.xyz;
	l.intensity = offset0.w;
	l.color     = offset1.xyz;
	l.range     = offset1.w;
	return l;
}

MySpotLight GetMySpotLight(int idx) {
	float i = idx * 4;
	float4 offset0 = my_spotLightBuf[i + 0];
	float4 offset1 = my_spotLightBuf[i + 1];
	float4 offset2 = my_spotLightBuf[i + 2];
	float4 offset3 = my_spotLightBuf[i + 3];

	MySpotLight l;
	l.position  = offset0.xyz;
	l.range		= offset0.w;
	l.direction = offset1.xyz;
	l.intensity = offset1.w;
	l.color		= offset2.xyz;
	l.cosOuter  = offset2.w;
	l.invAngDif = offset3.x;
	return l;
}

MyPointLight MyPointLightConstructor(MySpotLight s) {
	MyPointLight p;
	p.position  = s.position;
	p.intensity = s.intensity;
	p.color = s.color;
	p.range = s.range;
	return p;

}
#endif

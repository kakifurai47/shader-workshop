Shader "Week05/MyDeferLit"
{
	Properties
	{
		_BaseColor("Color", Color) = (1, 1, 1, 1)
		_BaseMap("MainTex", 2D) = "white" {}

		_DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)

		_Shininess("Shininess", Float) = 0
		[Toggle]_Debug("Debug", Float) = 0
	}

	SubShader{
		

		Pass{
			Name "GBufferWriting"
			Tags {"RenderType" = "Opaque" "Queue" = "Geometry" "LightMode" = "DeferredLit"}

			HLSLPROGRAM

			#pragma vertex	 vs
			#pragma fragment fs_mrt

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

			struct Attributes 
			{
				float3 positionOS : POSITION;
				float3 normalOS   : NORMAL;
			};

			struct Varyings 
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS   : TEXCOORD1;
			};

			struct GBuffer
			{
				float4 baseColorRT  : SV_Target0;
				float4 positionWSRT : SV_Target1;
				float4 normalWSRT   : SV_Target2;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			float4 _DiffuseColor;
			float4 _SpecularColor;
			float  _Shininess;
			float  _Debug;
			CBUFFER_END

			Varyings vs(Attributes i) 
			{
				Varyings o;
				o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
				o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
				o.normalWS   = TransformObjectToWorldNormal(i.normalOS.xyz);

				return o;
			}

			GBuffer fs_mrt(Varyings i) 
			{
				GBuffer buffer;
				buffer.baseColorRT  = _BaseColor;
				buffer.positionWSRT = float4(i.positionWS, _Shininess);
				buffer.normalWSRT   = float4(i.normalWS,   1);

				return buffer;
			}
			ENDHLSL
		}
	}
}

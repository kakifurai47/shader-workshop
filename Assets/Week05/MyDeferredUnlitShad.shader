Shader "Custom/MyDeferredUnlitShad"
{
    Properties
    {
		_BaseColor("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }

	SubShader{

		Pass{
			Name "GBufferWriting"
			Tags {"RenderType" = "Opaque" "Queue" = "Geometry" "LightMode" = "DeferredUnlit"}

			HLSLPROGRAM

			#pragma vertex	 vs
			#pragma fragment fs

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

			struct Attributes
			{
				float3 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _BaseColor;
			CBUFFER_END

			Varyings vs(Attributes i)
			{
				Varyings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				return o;
			}

			float4 fs(Varyings i) : SV_Target
			{
				return _BaseColor;
			}
			ENDHLSL
		}
	}



}

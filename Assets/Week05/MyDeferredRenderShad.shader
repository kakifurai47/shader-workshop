Shader "Week05/MyDeferredRenderShad"
{
	SubShader{
		Pass{
			Name "DeferredShading"
			Cull Off ZWrite Off ZTest Always

			HLSLPROGRAM

			#pragma vertex	 vs
			#pragma fragment fs

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uv          : TEXCOORD0;
			};

			uniform sampler2D _BaseColorRT;
			uniform sampler2D _PositionWSRT;
			uniform sampler2D _NoramlWSRT;

			#include "../Week04/LitShader/MyLightCommon.hlsl"
			
			#include "MyDeferredLighting.hlsl"

			Varyings vs(float4 positionOS : POSITION)
			{
				Varyings o;
				o.positionHCS = float4(positionOS.xy, 0.0, 1.0);
				o.uv = positionOS.xy * 0.5 + 0.5;

				//#if UNITY_UV_STARTS_AT_TOP
				//o.uv.y = 1 - o.uv.y;
				//#endif

				return o;
			}

			float4 fs(Varyings i) : SV_Target
			{
				float4 baseColor  = tex2D(_BaseColorRT,  i.uv);
				float4 positionWS = tex2D(_PositionWSRT, i.uv);
				float4 normalWS   = tex2D(_NoramlWSRT,   i.uv);

				MySurfaceData surf;
				surf.position = positionWS.xyz;
				surf.shininess = positionWS.w;
				surf.normal = normalWS.xyz;

				float4 unlitColor = baseColor;
				float4 outputColor = float4(0, 0, 0, 1);

				for (int p = 0; p < my_pointLightSize; p++) {
					MyPointLight ptLight = GetMyPointLight(p);
					outputColor += unlitColor * GetPointLightShading(surf, ptLight);
				}

				for (int s = 0; s < my_spotLightSize; s++) {
					MySpotLight spotLight = GetMySpotLight(s);
					outputColor += unlitColor * GetSpotLightShading(surf, spotLight);
				}

				//return float4(positionWS.xyz, 1);
				//return float4(normalWS.xyz, 1);

				return outputColor;

			}
			ENDHLSL
		}
	}
}

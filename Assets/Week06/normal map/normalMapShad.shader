Shader "Week06/NormalMapShad"
{
    Properties
    {
		_BaseColor("Color", Color) = (1, 1, 1, 1)
		_NormalMap("NormalMap", 2D) = "white" {}

		_DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)

		_Shininess("Shininess", Float) = 0
        [Toggle]_Debug("Debug", Float) = 0
    }

    SubShader
    {
        Tags {"RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Name "MyNoramlMap"

            HLSLPROGRAM

            #pragma vertex   vs
            #pragma fragment fs

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"


            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float3 tangentWS  : TEXCOORD2;
                float2 uv         : TEXCOORD3;
            };

            sampler2D _NormalMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _NormalMap_ST;
            float4 _BaseColor;
            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Shininess;
            float _Debug;
            CBUFFER_END

            #include "../../Week04/LitShader/MyLightCommon.hlsl"
            #include "../../Week04/LitShader/MyLightEquation.hlsl"

            float4 debug_float(float i) {
                return float4(i, i, i, 1);
            }

            Varyings vs(Attributes i)
            {
                Varyings o;

                
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.normalWS   = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.tangentWS  = TransformObjectToWorldNormal(i.tangentOS.xyz);
                o.uv = TRANSFORM_TEX(i.uv, _NormalMap);

                return o;
            }

            float4 fs(Varyings i) : SV_Target
            {
                float3 n = normalize(i.normalWS);
                float3 t = normalize(i.tangentWS);
                float3 b = cross(t, n);
                float3x3 TBN = float3x3(t, b, n);
                
                float3 normalTS = tex2D(_NormalMap, i.uv).xyz * 2.0 - 1.0;
                float3 normalWS = mul(normalTS, TBN);

                float4 unlitColor = _BaseColor;
                float4 outputColor = float4(0, 0, 0, 1);

                for (int p = 0; p < my_pointLightSize; p++) {
                    MyPointLight ptLight = GetMyPointLight(p);
                    outputColor += unlitColor * GetPointLightShading(i.positionWS, normalWS, ptLight);
                }

                for (int s = 0; s < my_spotLightSize; s++) {
                    MySpotLight spotLight = GetMySpotLight(s);
                    outputColor += unlitColor * GetSpotLightShading(i.positionWS, normalWS, spotLight);
                }

                return outputColor;
            }
            ENDHLSL
        }

    }






}

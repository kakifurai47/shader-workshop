Shader "Custom/MyLitShad"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _BaseMap("MainTex", 2D) = "white" {}
        
        _DiffuseColor("DiffuseColor", Color) = (1,1,1,1)
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)

        _Shininess("Shininess", Float) = 0
        [Toggle]_Debug("Debug", Float) = 0
        [Toggle]_BatchBreaker("Batch Breaker", Float) = 0
    }

        SubShader
    {
        Tags {"RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Name "MyLit"
            //Tags{"LightMode" = "MyDeferredLit"}

            HLSLPROGRAM

            #pragma vertex   vs
            #pragma fragment fs

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"


            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Shininess;
            float _Debug;
            CBUFFER_END
            
            float _BatchBreaker;

            #include "MyLightCommon.hlsl"
            #include "MyLightEquation.hlsl"

            float4 debug_float(float i) {
                return float4(i, i, i, 1);
            }

            Varyings vs(Attributes i)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
                o.normalWS   = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.uv = i.uv;

                return o;
            }

            float4 fs(Varyings i) : SV_Target
            {                
                float4 unlitColor = _BaseColor * tex2D(_BaseMap, i.uv);
                float4 outputColor = float4(0, 0, 0, 1);
                
                for (int p = 0; p < my_pointLightSize; p++) {
                    MyPointLight ptLight = GetMyPointLight(p);
                    outputColor += unlitColor * GetPointLightShading(i.positionWS, i.normalWS, ptLight);
                }

                for (int s = 0; s < my_spotLightSize; s++) {
                    MySpotLight spotLight = GetMySpotLight(s);
                    outputColor += unlitColor * GetSpotLightShading(i.positionWS, i.normalWS, spotLight);
                    //TODO: reuse GetPointShading();
                }

                return outputColor + (_BatchBreaker * 0.000001);
            }
            ENDHLSL
        }

    }

}

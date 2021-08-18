Shader "Custom/WaterShad"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _UnderWaterColor("Color", Color) = (1,1,1,1)
        _BaseMap("MainTex", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "Queue" = "Geometry+10" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        ZWrite Off//<=problematic
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma vertex   vs
            #pragma fragment fs

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _UnderWaterColor;
            float _WaterLv;
            CBUFFER_END

            Varyings vs(Attributes i)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);

                return o;
            }


            float4 fs(Varyings i) : SV_Target
            {
                if (i.positionWS.y > _WaterLv) {
                    return _UnderWaterColor;
                }

                return _BaseColor;
            }
            ENDHLSL
        }
    }

}

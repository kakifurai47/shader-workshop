Shader "Custom/WaterObjShad"
{
    Properties
    {
        _TopColor("Top Color"   , Color)     = (1, 1, 1, 1)
        _EdgColor("Water Edge Color", Color) = (1, 1, 1, 1)
        _MidColor("Middle Color", Color)     = (1, 1, 1, 1)
        _BotColor("Bottom Color", Color)     = (1, 1, 1, 1)
        _BaseMap("MainTex", 2D) = "white" {}

        _Darkness("Water Darkness", Float) = 0
        _EdgeSharp("Water Sharpness", Float) = 0
    }

    SubShader
    {
        Tags { "Queue" = "Geometry+20" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

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
            float4 _TopColor;
            float4 _EdgColor;
            float4 _MidColor;
            float4 _BotColor;

            float _WaterLv;
            float _Darkness;
            float _EdgeSharp;

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
                float topMask = step(i.positionWS.y, _WaterLv);                        
                
                float t = (_WaterLv - i.positionWS.y) / (_Darkness + 1e-4);
                t = saturate(1 - t);
                float4 mid_color = lerp(_MidColor, _EdgColor, pow(t, _EdgeSharp));
                float4 bot_color = lerp(_BotColor, mid_color, t);

                return lerp(_TopColor, bot_color, topMask);
            }
            ENDHLSL
        }
    }

}

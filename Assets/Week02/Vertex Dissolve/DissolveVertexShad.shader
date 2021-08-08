Shader "Custom/DissolveVertexShad"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _BaseMap("MainTex", 2D) = "white" {}
        _NoiseMap("NoiseTex", 2D) = "white" {}
        [Toggle]_Mode("Mode", Float) = 0
        _TimeStamp("TimeStamp", Range(0,1)) = 0
        _NFactorTh("Norm Factor Threshold", Range(0, 1)) = 0.5
        
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300

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
                float4 normalOS   : NORMAL;
                float4 texcoord   : TEXCOORD0;
                float4 vanishPt   : TEXCOORD1;
            };

            struct Varyings
            {                
                float4 positionCS : SV_POSITION;
                float4 color      : TEXCOORD2;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD0;                
            };

            sampler2D _BaseMap;
            sampler2D _NoiseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float  _TimeStamp;
            float  _NFactorTh;
            float  _Mode;
            CBUFFER_END

            float m_easeOut(float min, float max, float w) {
                float t = clamp((w - min) / (max - min), 0.0, 1.0);
                return 0.5 * t * (4.0 - 2.0 * t);
            }

            Varyings vs(Attributes i)
            {
                const static float m_epsilon = 1e-4;

                Varyings o = (Varyings)0;   
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                float3 vanishPtWS = TransformObjectToWorld(i.vanishPt.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(i.normalOS.xyz);

                float rdm = tex2Dlod(_NoiseMap, float4(i.texcoord.zw, 0, 0)).x;
                float wgt = smoothstep(0, 1, -rdm + _TimeStamp * 2);
                float nft = _NFactorTh + m_epsilon;

                float3 vanishingPos = lerp(positionWS, vanishPtWS, wgt);
                float3 up_Factor    = float3(0, 2, 0) * wgt;
                float3 norm_Factor  = 2 * normalWS * m_easeOut(0, 1, wgt / nft) * nft;

                float3 pos = vanishingPos + up_Factor + norm_Factor;

                o.positionCS = TransformWorldToHClip(pos);
                o.uv = TRANSFORM_TEX(i.texcoord, _BaseMap);
                o.normalWS = normalWS;
                o.color = float4(wgt, wgt, wgt, 1);

                return o;
            }

            float4 fs(Varyings i) : SV_Target
            {
                //return i.color;
                //return float4(i.normalWS, 1);

                float4 mainTex = tex2D(_BaseMap, i.uv);
                return mainTex;
            }
            ENDHLSL
        }
    }
}

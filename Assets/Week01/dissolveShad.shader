Shader "Custom/dissolveShader"
{
    Properties
    {
        _BaseColor ("Color",   Color) = (1, 1, 1, 1)
        _BaseMap   ("MainTex",    2D) = "white" {}
        _OverlayMap("OverlayTex", 2D) = "white" {}
        _MaskMap   ("MaskTex",    2D) = "white" {}

        _Dissolve      ("Dissolve",       Range(0.0, 1.0)) = 0.5
        _EdgeWidth     ("EdgeWidth",      Range(0.0, 1.0)) = 0.5
        _EdgeSmoothness("EdgeSmoothness", Range(0.0, 1.0)) = 0.5

        _EdgeColor     ("EdgeColor", Color) = (1, 1, 1, 1)

        [Toggle]_Debug("Debug", Float) = 0
        [Toggle]_EdgeDisplay("Edge Display", Float) = 0
        [Toggle]_StartEdge("Start Edge", Float) = 0
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
                float2 texcoord   : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv         : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_OverlayMap);
            TEXTURE2D(_MaskMap);

            SAMPLER(sampler_BaseMap);            
            SAMPLER(sampler_OverlayMap);
            SAMPLER(sampler_MaskMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;

            float _Dissolve;
            float _EdgeWidth;
            float _EdgeSmoothness;

            float4 _EdgeColor;

            float _Debug;
            float _EdgeDisplay;
            float _StartEdge;
            CBUFFER_END

            #define M_EPSILON 0.00000000000000000000000001

            Varyings vs(Attributes i) 
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = TRANSFORM_TEX(i.texcoord, _BaseMap);

                return o;
            }

            float4 debug_th(float th) {
                return float4(float3(1, 1, 1) * th, 1);
            }

            float4 fs(Varyings i) : SV_Target
            {
                float4 mainTex     = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float4 overlayTex  = SAMPLE_TEXTURE2D(_OverlayMap, sampler_OverlayMap, i.uv);
                float  maskTex = 1 - SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv).x;

                float dissolve = _Dissolve + M_EPSILON; //ensure step(_dissolve = 0, mask = 0) != 0
                float dissolve_mask = step(maskTex, dissolve);

                float norm_max_edge_width = _EdgeWidth * dissolve;
                float norm_min_edge_width = _EdgeWidth - norm_max_edge_width;

                float lower_edge = dissolve - norm_min_edge_width;
                float highr_edge = dissolve + norm_max_edge_width;

                float norm_max_soft_width = _EdgeSmoothness * dissolve;
                float norm_min_soft_width = _EdgeSmoothness - norm_max_soft_width;

                float lower_soft = lower_edge - norm_min_soft_width;
                float highr_soft = highr_edge + norm_max_soft_width;

                float lower_th = smoothstep(lower_soft, lower_edge, maskTex);
                float highr_th = smoothstep(highr_edge, highr_soft, maskTex);

                float temp_mask = step(maskTex, highr_edge);
                float fina_mask = lerp(1 - lower_th, highr_th, 1 - temp_mask);

                float4 fina_color = lerp(mainTex, overlayTex, dissolve_mask);
                return lerp(_EdgeColor, fina_color, fina_mask);
            }
            ENDHLSL            
        }

    }
}
//trash
////https://www.desmos.com/calculator/a3owmyfb1n
//float sMax = _EdgeSmoothness * dissolve;
//float sMin = _EdgeSmoothness - sMax;
//float min = dissolve - sMin;
//float max = dissolve + sMax;
//
//float threshold = smoothstep(min, max, maskTex);
//float threshold2 = pow(threshold, 2);
//fin_color = debug_th(threshold2);
//return fin_color;
////return lerp(overlayTex, _EdgeColor, 1 - threshold2); 
//return fin_color;

Shader "Custom/ScannerShad"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _BaseMap("MainTex", 2D) = "white" {}

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0

        _ScanDistance("Radius", Range(0,100)) = 0
        _ScanWidth("Scan Width", Range(0,10)) = 0
        _SoftWidth("Soft Width", Range(0,10)) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        ZTest Always
        ZWrite Off
        Blend[_SrcBlend][_DstBlend]

        Pass
        {

            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma vertex   vs
            #pragma fragment fs

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float3 _ScannerTransform;
            float _ScanDistance;
            float _ScanWidth;
            float _SoftWidth;
            CBUFFER_END

            Varyings vs(Attributes i)
            {   
                Varyings o;
                
                o.positionHCS = float4(i.positionOS.xy , 0.0, 1.0);
                o.uv = i.positionOS.xy * 0.5 + 0.5;

#if UNITY_UV_STARTS_AT_TOP
                o.uv.y = 1 - o.uv.y;                    
#endif
                return o;
            }

            float4 debug_float(float i) {
                return float4(i, i, i, i);
            }

            float4 fs(Varyings i) : SV_Target
            {
                static const float m_ep = 1e-4;

#if UNITY_REVERSED_Z
                float norm_depth = SampleSceneDepth(i.uv);
#else
                float norm_depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
#endif           
                float3 wrldPos = ComputeWorldSpacePosition(i.uv, norm_depth, UNITY_MATRIX_I_VP);

                float3 dif = wrldPos - _ScannerTransform;
                float  len = length(dif);

                float t    = len * step(len, _ScanDistance);
                float e1   = max(0, _ScanDistance - _ScanWidth);
                float e0   = max(0, e1 - _SoftWidth);
                float mask = smoothstep(e0, e1 + m_ep, t);

                float m = (t - e0) / (_ScanDistance + m_ep - e0);
                float2 uv = float2(m, 0);
                float2 uv_st = uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 m_col = float4(tex2D(_BaseMap, uv_st).xyz, mask);
                
                return m_col;
            }
            ENDHLSL
        }
    }
}

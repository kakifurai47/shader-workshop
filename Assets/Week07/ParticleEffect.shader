Shader "Unlit/ParticleEffect"
{
    Properties
    {
        //_Color ("Color", Color) = (1,1,1,1)
        _BaseMap("MainTex", 2D) = "white" {}
        //_Glossiness ("Smoothness", Range(0,1)) = 0.5
        //_Metallic ("Metallic", Range(0,1)) = 0.0

        _BaseColor("Color", Color) = (1, 1, 1, 1)

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
    }
        SubShader
    {
        Tags {"RenderType" = "Transparent" "Queue" = "Transparent" }

        ZWrite Off
        Blend[_SrcBlend][_DstBlend]

        Pass
        {
            Name "MyParticleShader"

            HLSLPROGRAM

            #pragma vertex   vs
            #pragma fragment fs

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

            //#include "ParticleEffectCommon.hlsl"

            struct VertexInputs {
                float3 positionOS;
                float2 uv;
                //float3 normalOS;
                //float2 uv;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                //float3 normalWS   : TEXCOORD0;
            };

            sampler2D _BaseMap;

            StructuredBuffer<VertexInputs> ParticleEffect_CombineVtxs;
            StructuredBuffer<uint>         ParticleEffect_CombineIdxs;

            VertexInputs GetVertexInputs(uint vid) {
                VertexInputs v;
                uint idx = ParticleEffect_CombineIdxs[vid];
                v = ParticleEffect_CombineVtxs[idx];
                return v;
            }

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            CBUFFER_END

            Varyings vs(uint vid : SV_VertexID)
            {
                VertexInputs i = GetVertexInputs(vid);

                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS);
                o.uv = i.uv;
                
                //o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                return o;
            }

            float4 fs(Varyings i) : SV_Target
            {
                return tex2D(_BaseMap, i.uv);
            }
            ENDHLSL
        }
    }



}

Shader "Custom/bottleShad"
{
    Properties
    {
        _Height("Height", Float) = 0

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
    }

    SubShader
    {
        Tags {"RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend[_SrcBlend][_DstBlend]
        Cull Off
        ZWrite On

        Pass {
            Name "MyBottleShader"

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
                float4 positionWS : TEXCOORD2;
                float3 normalWS   : TEXCOORD0;
                float2 uv         : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _Plane;
            CBUFFER_END

            Varyings vs(Attributes i)
            {
                Varyings o;
                o.positionWS = float4(TransformObjectToWorld(i.positionOS.xyz), 1);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);                
                o.uv = i.uv;

                return o;
            }

            float4 fs(Varyings i, bool facing : SV_IsFrontFace) : SV_Target
            {
                if (dot(i.positionWS, _Plane) > 0) {
                    discard;
                }

                float3 c = lerp(float3(1, 0, 0), float3(0, 1, 0), facing);
                return float4(c, 1);
            }
            ENDHLSL
        }
    }
}

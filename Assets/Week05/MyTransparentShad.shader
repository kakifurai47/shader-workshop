Shader "Custom/MyTransparentShad"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)

        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "LightMode" = "DeferredUnlit"}
        ZWrite Off
        Blend[_SrcBlend][_DstBlend]

        Pass
        {
            Name "MyTransparentLit"

            HLSLPROGRAM

            #pragma vertex   vs
            #pragma fragment fs

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"


            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            CBUFFER_END


            float4 debug_float(float i) {
                return float4(i, i, i, 1);
            }

            Varyings vs(Attributes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            float4 fs(Varyings i) : SV_Target
            {
                return _BaseColor;
            }
            ENDHLSL
        }
    }

}

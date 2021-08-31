Shader "Custom/PlotGraph"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_LineWidth("LineWidth", range(1, 50)) = 4
		_Param("Param", Vector) = (0,0,0,0)

		_ScanDistance("Radius", Range(0,10)) = 0
		_ScanWidth("Scan Width", Range(0,10)) = 0
		_SmoothWidth("Smooth Width", Range(0, 10)) = 0

		_Debug1("Debug1", Float) = 0
		_Debug2("Debug2", Float) = 0
		_Debug3("Debug3", Float) = 0


		[Toggle]_Toggle("Toggle", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		Cull off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _LineWidth;
			float4 _Param;

			float _ScanDistance;
			float _ScanWidth;
			float _SmoothWidth;

			float _Debug1;
			float _Debug2;
			float _Debug3;


			float _Toggle;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			float func(float x) {//x = len;
				//float t1 = abs(x - _ScanDistance);
				//if (_Toggle) {
				//	return t1;
				//}
				//else {
				//	return smoothstep(_Debug1, _Debug2, t1);
				//}

				static const float m_ep = 1e-4;

				float t = max(0, x * step(x, _ScanDistance));
				if (_Toggle) {
					return t;
				}
				else {
					float inner = max(0, _ScanDistance - _ScanWidth);//note: scan width should not > distance
					float e0 = max(0, inner - _SmoothWidth);
					float e1 = max(0, _ScanDistance - _ScanWidth);
					float mask = smoothstep(e0, e1 + m_ep, t);
					return mask;
				}



					
			}

			float4 frag(v2f i) : SV_Target
			{
				float4 tex = tex2D(_MainTex, i.uv);

				float2 graphCoord = (i.uv - 0.5) * 10;

				float w = _LineWidth * ddy(i.uv.y);
				float value = func(graphCoord.x);
				value = w / abs(graphCoord.y - value);

				return lerp(tex, float4(1,0,0,1), saturate(value));
			}

			ENDCG
		}
	}
}
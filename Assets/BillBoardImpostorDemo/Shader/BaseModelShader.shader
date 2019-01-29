// 用来简单展示真实的模型
Shader "ImpostorDemo/BaseModelShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_DiffuseColor ("DiffuseColor", Color) = (1,1,1,1)
		_Diffuse ("Diffuse", Range(0,1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 diffuseColor : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			// 漫反射强度
			float4 _DiffuseColor;
			float _Diffuse;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				// 漫反射
				float3 worldlight = normalize(_WorldSpaceLightPos0.xyz);
				float3 worldnormal = normalize(mul(v.normal, (float3x3)unity_ObjectToWorld));
				float3 diffuse = _LightColor0.rgb * saturate(dot(worldnormal,worldlight));
				o.diffuseColor = float4(diffuse,0);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.w - 0.5f);   
				float4 ambientColor = 1.0;
                return col * (i.diffuseColor + ambientColor * 0.5);
            }
            ENDCG
        }
    }
}

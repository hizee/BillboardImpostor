// 用来展示BillboardImpostor模型
Shader "ImpostorDemo/BillboardImpostor"
{
	Properties
	{
		[NoScaleOffset]_Albedo("Impostor Albedo & Alpha", 2D) = "white" {}
		[NoScaleOffset]_Normals("Impostor Normal & Depth", 2D) = "white" {}
		[NoScaleOffset]_Mask("Mask", 2D) = "white" {}
		[HideInInspector]_AI_Frames("Impostor Frames", Float) = 0
		[HideInInspector]_AI_ImpostorSize("Impostor Size", Float) = 0
		_AI_Clip("Impostor Clip", Range( 0 , 1)) = 0.5
		
		_DiffuseColor ("DiffuseColor", Color) = (1,1,1,1)
		_Diffuse ("Diffuse", Range(0,1)) = 1.0
	}

	SubShader
	{
		CGINCLUDE
		#pragma target 3.0
		#define UNITY_SAMPLE_FULL_SH_PER_PIXEL 1
		ENDCG
		Tags { "RenderType"="Opaque" "Queue"="Geometry" "DisableBatching"="True" "ImpostorType"="Octahedron" }
		Cull Back
		Pass
		{
			ZWrite On
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			uniform sampler2D _Albedo; // 颜色
			uniform sampler2D _Normals; // 法线
			uniform sampler2D _Mask;// mask
			uniform float _AI_Frames; // 切片规模
			uniform float _AI_ImpostorSize; // impostor resolution
			uniform float _AI_Clip; // 透明背景裁剪程度
			
			// 漫反射强度
			uniform float4 _DiffuseColor;
			uniform float _Diffuse;

			// 空间纹理映射变换
			float2 VectortoOctahedron( float3 N )
			{
				N /= dot( 1.0, abs( N ) ); // N/= abs(N.x)+abs(N.y)+abs(N.z)
				if( N.z <= 0 )
				{
				    N.xy = ( 1 - abs( N.yx ) ) * ( N.xy >= 0 ? 1.0 : -1.0 );
				}
				return N.xy;
			}
			
			float3 OctahedronToVector( float2 Oct )
			{
				float3 N = float3( Oct, 1.0 - dot( 1.0, abs( Oct ) ) );
				if(N.z< 0 )
				{
				    N.xy = ( 1 - abs( N.yx) ) * (N.xy >= 0 ? 1.0 : -1.0 );
				}
				return normalize( N);
			}
			
			inline void OctaImpostorVertex( inout appdata_full v, inout float4 uvsFrame1)
			{
				float framesXY = _AI_Frames;
				float prevFrame = framesXY - 1;
				float2 fractions = 1.0 / float2( framesXY, prevFrame );
				float fractionsFrame = fractions.x;
				float fractionsPrevFrame = fractions.y;
				float UVscale = _AI_ImpostorSize;

				float3 worldOrigin = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);

				float3 worldCameraPos = _WorldSpaceCameraPos;

				// 模型空间：origin到相机的方向
				float3 objectCameraDirection = normalize( mul( (float3x3)unity_WorldToObject, worldCameraPos - worldOrigin ) );
				// 模型空间：相机的位置
				float3 objectCameraPosition = mul( unity_WorldToObject, float4( worldCameraPos, 1 ) ).xyz;
				float3 upVector = float3( 0,1,0 );
				//float3 objectCameraDirection = UNITY_MATRIX_V[2].xyz;

				// 模型水平竖直向量
				float3 objectHorizontalVector = normalize( cross( objectCameraDirection, upVector ) );
				float3 objectVerticalVector = cross( objectHorizontalVector, objectCameraDirection );

				float2 uvExpansion = ( v.texcoord.xy - 0.5f ) * UVscale;
				float3 billboard = objectHorizontalVector * uvExpansion.x + objectVerticalVector * uvExpansion.y;

				float2 cameraPos = VectortoOctahedron(objectCameraDirection.xzy)*0.5 + 0.5;
				float colFrame = round(abs(cameraPos.x) * (framesXY-1));
				float rowFrame = round(abs(cameraPos.y) * (framesXY-1));
				// 纹理坐标
				uvsFrame1 = 0;
				uvsFrame1.xy = (v.texcoord.xy + float2(colFrame, rowFrame)) * fractionsFrame;

				// 顶点
				v.vertex.xyz = billboard;
				v.normal.xyz = objectCameraDirection;
			}

			struct v2f_surf {
				UNITY_POSITION(pos);
				float4 UVsFrame117 : TEXCOORD5;
				float4 viewPos17 : TEXCOORD6;
			};

		    // 顶点
			v2f_surf vert (appdata_full v ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				OctaImpostorVertex( v, o.UVsFrame117 ); ///
				o.pos = UnityObjectToClipPos(v.vertex); // 顶点投影坐标

				return o;
			}

			// 片段着色
			fixed4 frag (v2f_surf IN) : SV_Target {	
			    // 漫反射
				float3 worldlight = normalize(_WorldSpaceLightPos0.xyz);
				float4 imNormal = tex2D( _Normals, float3( IN.UVsFrame117.xy, 0) );
				float3 worldnormal = normalize(mul(imNormal.rgb, (float3x3)unity_ObjectToWorld));
				float3 diffuse = _LightColor0.rgb * saturate(dot(worldnormal,worldlight));

				// Diffuse
				float4 blendedAlbedo = tex2D( _Albedo, float3( IN.UVsFrame117.xy, 0) );
				float alpha = blendedAlbedo.a - _AI_Clip;
				clip(alpha);

				return (blendedAlbedo * float4(diffuse,0));
			}

			ENDCG
		}
		
	}
}

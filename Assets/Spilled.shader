// babsed on this shader by flockaroo on shadertoy https://www.shadertoy.com/view/MsGSRd
Shader "Unlit/Spilled"
{
    Properties
    {
		//iChannel0("Channel0", 2D) = "white" {}
		_MainTex("main tex", 2D) = "white" {}
		iChannel1("Channel1", 2D) = "white" {}
		iChannel2("Channel2", 2D) = "white" {}
		iChannelResolutionA("ResolutionA", Vector) = (1920, 1080, 0, 0)
		iChannelResolutionB("ResolutionB", Vector) = (1920, 1080, 0, 0)
		//iFrame("Frame", int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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
			float4 _iChannel0_ST;

			sampler2D _iChannel0;
			sampler2D iChannel1;
			sampler2D iChannel2;
			//float4 _ResolutionA;
			float4 iChannelResolutionA;
			float4 iChannelResolutionB;

			//int iFrame;

			#define RotNum 5
			//static const float RotNum = 5.0f;
			//#define SUPPORT_EVEN_ROTNUM

			#define Res  iChannelResolutionA.xy
			#define Res1 iChannelResolutionB.xy

			#define keyTex iChannel3
			#define KEY_I texture(keyTex,float2((105.5-32.0)/256.0,(0.5+0.0)/3.0)).x

			static const float ang = (2.0*3.1415926535) / float(RotNum);
			//mat2 m = mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
			//mat2 mh = mat2(cos(ang*0.5), sin(ang*0.5), -sin(ang*0.5), cos(ang*0.5));

			static const float2x2 m = float2x2(cos(ang), sin(ang), -sin(ang), cos(ang));
			//static const float2x2 m = float2x2(cos(ang), -sin(ang), sin(ang), cos(ang));
			static const float2x2 mh = float2x2(cos(ang*0.5), sin(ang*0.5), -sin(ang*0.5), cos(ang*0.5));
			//static const float2x2 mh = float2x2(cos(ang*0.5), -sin(ang*0.5), sin(ang*0.5), cos(ang*0.5));

			float4 randS(float2 uv)
			{
				return tex2D(iChannel1, (uv*Res.xy) / Res1.xy) - float4(0.5, 0.5, 0.5, 0.5);
			}

			float getRot(float2 pos, float2 b)
			{
				float2 p = b;
				float rot = 0.0;
				[unroll(RotNum)]for (int i = 0; i < RotNum; i++)//for (int i = 0; i < RotNum; i++)
				{
					rot += dot(tex2D(_iChannel0, frac((pos + p) / Res.xy)).xy - float2(0.5, 0.5), p.yx*float2(1, -1));
					//p = m * p;
					//https://en.wikibooks.org/wiki/GLSL_Programming/Vector_and_Matrix_Operations
					/*
					vec2 v = vec2(10., 20.);
					mat2 m = mat2(1., 2.,  3., 4.);
					vec2 w = m * v; // = vec2(1. * 10. + 3. * 20., 2. * 10. + 4. * 20.)
					*/
					//p = float2(m[0][0] * p.x + m[0][1] * p.y, m[1][0] * p.x + m[1][1] * p.y);
					// now I realise that you can simply use 'mul' function, but anyway
					p = float2(m[0][0] * p.x + m[1][0] * p.y, m[0][1] * p.x + m[1][1] * p.y);
				}
				return (rot / float(RotNum)) / dot(b, b);
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

				float2 pos = i.uv * Res;// _ScreenParams.xy;// fragCoord.xy;
				//float rnd = randS(float2(float(iFrame)/ Res.x, 0.5 / Res1.y)).x;
				float rnd = randS(float2(float(_Time.y) / Res.x, 0.5 / Res1.y)).x;

				float2 b = float2(cos(ang*rnd), sin(ang*rnd));
				float2 v = float2(0, 0);
				float bbMax = 0.7*Res.y; bbMax *= bbMax;
				//[unroll(20)] for (int l = 0; l < 20; l++)
				[unroll(20)]for (int l = 0; l < 20; l++)
				{
					if (dot(b, b) > bbMax) break;
					float2 p = b;
					//[unroll(RotNum)]
					[unroll(RotNum)]for (int i = 0; i < RotNum; i++)
					{
						//#ifdef SUPPORT_EVEN_ROTNUM
						//v += p.yx*getRot(pos + p, -mh * b);
						//#else
						// this is faster but works only for odd RotNum
						v += p.yx*getRot(pos + p, b);
						//#endif
						//p = m * p;
						//p = float2(m[0][0] * p.x + m[0][1] * p.y, m[1][0] * p.x + m[1][1] * p.y);
						p = float2(m[0][0] * p.x + m[1][0] * p.y, m[0][1] * p.x + m[1][1] * p.y);
					}
					b *= 2.0;
				}

				fixed4 col = tex2D(_iChannel0, frac((pos + v * float2(-1, 1)*2.0) / Res.xy));

				// add a little "motor" in the center
				float2 scr = (pos / Res.xy)*2.0 - float2(1.0, 1.0);
				//col.xy += (0.01*scr.xy / (dot(scr, scr) / 0.1 + 0.3));
				col.xy += (0.02*scr.xy / (dot(scr, scr) / 0.05 + 0.3+0.2*sin(_Time.y*0.5)));

				//if (iFrame <= 4) col = tex2D(iChannel2, i.uv);
				if (_Time.y <= 1) col = tex2D(iChannel2, i.uv);
				return col;

				//if (iFrame <= 4 || KEY_I > 0.5) fragColor = texture(iChannel2, fragCoord.xy / Res.xy);
            }
            ENDCG
        }
		GrabPass{"_bufferA"}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

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

			sampler2D _bufferA;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float getVal(float2 uv)
			{
				return length(tex2D(_bufferA, uv).xyz);
			}

			float2 getGrad(float2 uv, float delta)
			{
				float2 d = float2(delta, 0);
				return float2(
					getVal(uv + d.xy) - getVal(uv - d.xy),
					getVal(uv + d.yx) - getVal(uv - d.yx)
				) / delta;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv;// fragCoord.xy / iResolution.xy;
				float3 n = float3(getGrad(uv, 1.0 / _ScreenParams.y), 150.0);
				//n *= n;
				n = normalize(n);
				//fragColor = vec4(n, 1);
				//fixed4 col = float4(n, 1);
				float3 light = normalize(float3(1, 1, 2.5));
				float diff = clamp(dot(n, light), 0.5, 1.0);
				float spec = clamp(dot(reflect(light, n), float3(0, 0, -1)), 0.0, 1.0);
				spec = pow(spec, 36.0)* 2.5;
				//spec=0.0;
				return tex2D(_bufferA, uv)*float4(diff, diff, diff, diff) + float4(spec, spec, spec, spec);
			}
			ENDCG
		}
		GrabPass{ "_iChannel0" }
    }
}

Shader "Basics/TessellatedGrass"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseTexture("Base Texture", 2D) = "white" {}
        _WaveHeight("Wave Height", Range(0.0, 1.0)) = 0.25
        _WaveSpeed("Wave Speed", Range(0.0, 10.0)) = 1.0
        _TessellationAmount("Tessellation Amount", Range(1.0, 64.0)) = 1.0
        _TessellationFadeStart("Tessellation Fade Start", Float) = 25
        _TessellationFadeEnd("Tessellation Fade End", Float) = 50
        _GrassFloorColor("Grass Floor Color", Color) = (0, 0, 0, 1)
        _GrassTipColor("Grass Tip Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseTexture_ST;
                float _WaveHeight;
                float _WaveSpeed;
                float _TessellationAmount;
                float _TessellationFadeStart;
                float _TessellationFadeEnd;
                float4 _GrassFloorColor;
                float4 _GrassTipColor;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct tessControlPoint
            {
                float3 positionWS : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
            };

            struct tessFactors
			{
				float edge[3] : SV_TessFactor;
				float inside  : SV_InsideTessFactor;
			};

            struct t2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            tessControlPoint vert(appdata v)
            {
                tessControlPoint o = (tessControlPoint)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);

                return o;
            }

            [domain("tri")]
			[outputcontrolpoints(3)]
			[outputtopology("triangle_cw")]
			[partitioning("integer")]
			[patchconstantfunc("patchConstantFunc")]
            tessControlPoint hull(InputPatch<tessControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            tessFactors patchConstantFunc(InputPatch<tessControlPoint, 3> patch)
            {
                tessFactors f = (tessFactors)0;

				float3 triPos0 = patch[0].positionWS;
				float3 triPos1 = patch[1].positionWS;
				float3 triPos2 = patch[2].positionWS;

				float3 edgePos0 = 0.5f * (triPos1 + triPos2);
				float3 edgePos1 = 0.5f * (triPos0 + triPos2);
				float3 edgePos2 = 0.5f * (triPos0 + triPos1);

				float3 camPos = _WorldSpaceCameraPos;

				float dist0 = distance(edgePos0, camPos);
				float dist1 = distance(edgePos1, camPos);
				float dist2 = distance(edgePos2, camPos);

				float fadeDist = _TessellationFadeEnd - _TessellationFadeStart;

				float edgeFactor0 = saturate(1.0f - (dist0 - _TessellationFadeStart) / fadeDist);
				float edgeFactor1 = saturate(1.0f - (dist1 - _TessellationFadeStart) / fadeDist);
				float edgeFactor2 = saturate(1.0f - (dist2 - _TessellationFadeStart) / fadeDist);

				f.edge[0] = 1;//max(edgeFactor0 * _TessellationAmount, 1);
				f.edge[1] = 1;//max(edgeFactor1 * _TessellationAmount, 1);
				f.edge[2] = 1;//max(edgeFactor2 * _TessellationAmount, 1);

				f.inside = _TessellationAmount;//(f.edge[0] + f.edge[1] + f.edge[2]) / 3.0f;

				return f;
            }

            [domain("tri")]
            t2f domain(tessFactors factors, OutputPatch<tessControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                t2f i = (t2f)0;

                float3 positionWS = patch[0].positionWS * barycentricCoordinates.x +
					patch[1].positionWS * barycentricCoordinates.y +
					patch[2].positionWS * barycentricCoordinates.z;

                /*
                float2 uv = patch[0].uv * barycentricCoordinates.x +
					patch[1].uv * barycentricCoordinates.y +
					patch[2].uv * barycentricCoordinates.z;
                */

                float distancesFromPoint = min(barycentricCoordinates.x, min(barycentricCoordinates.y, barycentricCoordinates.z));

                float isAwayFromEdge = step(0.2f, distancesFromPoint);

                float3 newPositionWS = float3(positionWS.x, positionWS.y + isAwayFromEdge * distancesFromPoint, positionWS.z);

                i.positionCS = TransformWorldToHClip(newPositionWS);
                i.uv = isAwayFromEdge * distancesFromPoint;

                return i;
            }

            float4 frag(t2f i) : SV_TARGET
            {
                /*
                float4 textureColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv);
                return textureColor * _BaseColor;
                */

                return lerp(_GrassFloorColor, _GrassTipColor, i.uv.x);
            }

            ENDHLSL
        }
    }
}

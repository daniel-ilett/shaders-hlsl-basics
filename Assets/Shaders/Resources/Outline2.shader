Shader "Basics/Outline2"
{
    SubShader
    {
        Tags
		{
			"RenderPipeline" = "UniversalPipeline"
		}
        
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off

			HLSLPROGRAM
			#pragma vertex Vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

			float _Strength;
			float3 _OutlineColor;
			float _ColorThreshold;
			float _DepthThreshold;
			float _NormalThreshold;
			
			float4 frag(Varyings i) : SV_Target
			{
				float4 originalColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, i.texcoord);
				
				// Roberts Cross operator UV offsets.
				float2 blUV = i.texcoord + float2(0.0f, 0.0f);											// Bottom-left.
				float2 trUV = i.texcoord + float2(_BlitTexture_TexelSize.x, _BlitTexture_TexelSize.y);	// Top-right.
				float2 brUV = i.texcoord + float2(_BlitTexture_TexelSize.x, 0.0f);						// Bottom-right.
				float2 tlUV = i.texcoord + float2(0.0f, _BlitTexture_TexelSize.y);						// Top-left.
				
				// Color-based edge detection.
				float3 col0 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, blUV).rgb;
				float3 col1 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, trUV).rgb;
				float3 col2 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, brUV).rgb;
				float3 col3 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, tlUV).rgb;
				
				float3 colorGrad0 = col1 - col0;
				float3 colorGrad1 = col3 - col2;

				float colorEdge = sqrt(dot(colorGrad0, colorGrad0) + dot(colorGrad1, colorGrad1));
				colorEdge = colorEdge > _ColorThreshold ? _Strength : 0.0f;
				
				// Depth-based edge detection.
				float depth0 = Linear01Depth(SampleSceneDepth(blUV), _ZBufferParams);
				float depth1 = Linear01Depth(SampleSceneDepth(trUV), _ZBufferParams);
				float depth2 = Linear01Depth(SampleSceneDepth(brUV), _ZBufferParams);
				float depth3 = Linear01Depth(SampleSceneDepth(tlUV), _ZBufferParams);
				
				float depthGrad0 = depth1 - depth0;
				float depthGrad1 = depth3 - depth2;
				
				float depthEdge = sqrt(depthGrad0 * depthGrad0 + depthGrad1 * depthGrad1);
				depthEdge = depthEdge > _DepthThreshold ? _Strength : 0.0f;
				
				// Normal-based edge detection.
				float3 normal0 = SampleSceneNormals(blUV);
				float3 normal1 = SampleSceneNormals(trUV);
				float3 normal2 = SampleSceneNormals(brUV);
				float3 normal3 = SampleSceneNormals(tlUV);
				
				float normGrad0 = normal1 - normal0;
				float normGrad1 = normal3 - normal2;
				
				float normalEdge = sqrt(dot(normGrad0, normGrad0) + dot(normGrad1, normGrad1));
				normalEdge = normalEdge > _NormalThreshold ? _Strength : 0.0f;
				
				float edge = max(max(colorEdge, depthEdge), normalEdge);
				
				return float4(lerp(originalColor, _OutlineColor, edge), originalColor.a);
			}
			
			ENDHLSL
        }
    }
}

Shader "Basics/Outline"
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

			float _Strength;
			float3 _OutlineColor;
			float _ColorThreshold;
			
			float4 frag(Varyings i) : SV_Target
			{
				float4 originalColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, i.texcoord);
				
				float2 leftUV = i.texcoord + float2(-_BlitTexture_TexelSize.x, 0.0f);
				float2 rightUV = i.texcoord + float2(_BlitTexture_TexelSize.x, 0.0f);
				float2 bottomUV = i.texcoord + float2(0.0f, -_BlitTexture_TexelSize.y);
				float2 topUV = i.texcoord + float2(0.0f, _BlitTexture_TexelSize.y);
				
				float3 col0 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, leftUV).rgb;
				float3 col1 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, rightUV).rgb;
				float3 col2 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, bottomUV).rgb;
				float3 col3 = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, topUV).rgb;
				
				float3 grad0 = col1 - col0;
				float3 grad1 = col3 - col2;

				float edge = sqrt(dot(grad0, grad0) + dot(grad1, grad1));
				edge = edge > _ColorThreshold ? _Strength : 0.0f;
				
				return float4(lerp(originalColor, _OutlineColor, edge), originalColor.a);
			}
			
			ENDHLSL
        }
    }
}

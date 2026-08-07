Shader "Basics/Greyscale"
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
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			float _Strength;
			
			float4 frag(Varyings i) : SV_Target
			{
				float4 originalColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, i.texcoord);
				float3 newColor = Luminance(originalColor.rgb);
				
				return float4(lerp(originalColor, newColor, _Strength), originalColor.a);
			}
			
			ENDHLSL
        }
    }
}

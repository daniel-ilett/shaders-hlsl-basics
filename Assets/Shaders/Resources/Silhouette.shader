Shader "Basics/Silhouette"
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

			float4 _NearColor;
			float4 _FarColor;
			float _DepthPower;
			
			float4 frag(Varyings i) : SV_Target
			{
				float rawDepth = SampleSceneDepth(i.texcoord);
				float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);
				
				float depth = pow(linearDepth, _DepthPower);
				
				return lerp(_NearColor, _FarColor, depth);
			}
			
			ENDHLSL
        }
    }
}

Shader "Basics/Silhouette"
{
    Properties
    {
        _ForegroundColor("Foreground Color", Color) = (0, 0, 0, 0)
        _BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _ForegroundColor;
                float4 _BackgroundColor;
            CBUFFER_END

            struct appdata
            {
                float4 positionOS : POSITION;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 positionSS : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionSS = ComputeScreenPos(o.positionCS);

                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            {
                float2 screenUV = i.positionSS.xy / i.positionSS.w;
                float rawDepth = SampleSceneDepth(screenUV);

                float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);

                return lerp(_ForegroundColor, _BackgroundColor, linearDepth);
            }

            ENDHLSL
        }
    }
}

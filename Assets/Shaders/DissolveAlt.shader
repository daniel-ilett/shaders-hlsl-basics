Shader "Basics/DissolveAlt"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _BaseTexture("Base Texture", 2D) = "white" {}
        
        [Toggle(_SPECULAR_SETUP)] _UseSpecularSetup("Use Specular Setup", Integer) = 0

        [NoScaleOffset] _MetallicMap("Metallic", 2D) = "white" {}
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0

        [NoScaleOffset] _SpecularMap("Specular Map", 2D) = "white" {}
        _SpecularColor("Specular Color", Color) = (0.2, 0.2, 0.2, 1.0)

        [NoScaleOffset] _SmoothnessMap("Smoothness", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [Toggle(_CONVERT_FROM_ROUGHNESS)] _ConvertFromRoughness("Convert From Roughness", Integer) = 0

        [NoScaleOffset] [Normal] _NormalTexture("Normal Texture", 2D) = "bump" {}
        _NormalStrength("Normal Strength", Range(0.0, 2.0)) = 1.0

        [NoScaleOffset] _HeightMap("Height Map", 2D) = "white" {}
        _HeightMapStrength("Height Map Strength", Range(0.0, 0.1)) = 0.0
        
        [NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        
        [NoScaleOffset] _EmissionMap("Emission Map", 2D) = "white" {}
        [HDR] _EmissionColor("Emission Color", Color) = (0.0, 0.0, 0.0, 1.0)
        
        _NoiseScale("Noise Scale", Float) = 150
        _NoiseStrength("Noise Strength", Range(0.0, 1.0)) = 0.5
        _CutoffHeight("Cutoff Height", Float) = 0.0
        [HDR] _EdgeColor("Edge Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _EdgeThickness("Edge Thickness", Range(0.0, 0.2)) = 0.02
        _CycleSpeed("Cycle Speed", Range(0.0, 2.0)) = 1.0
        
        _NoiseType("Noise Type", Float) = 0.0
        [Toggle(_REVERSE_DIRECTION)] _ReverseDirection("Reverse Direction", Integer) = 0
        
        [HideInInspector] _Surface("_Surface", Float) = 0
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _SrcBlend("_SrcBlend", Float) = 1
        [HideInInspector] _DstBlend("_DstBlend", Float) = 0
        [HideInInspector] _SrcBlendAlpha("_SrcBlendAlpha", Float) = 1
        [HideInInspector] _DstBlendAlpha("_DstBlendAlpha", Float) = 0
        [HideInInspector] _ZWrite("_ZWrite", Float) = 1
        [HideInInspector] _ZTest("_ZTest", Float) = 4
        [HideInInspector] _Cull("_Cull", Float) = 2
        [HideInInspector] _AlphaToMask("_AlphaToMask", Float) = 0
        
        [HideInInspector] _CastShadows("_CastShadows", Float) = 1
        [HideInInspector] _ReceiveShadows("Receive Shadows", Float) = 1.0
        [HideInInspector] _Blend("_Blend", Float) = 0
        [HideInInspector] _AlphaClip("_AlphaClip", Float) = 0
        [HideInInspector] _ZWriteControl("_ZWriteControl", Float) = 0
        [HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = 0
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
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendAlpha] [_DstBlendAlpha]
            AlphaToMask [_AlphaToMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _FORWARD_PLUS   // Use _CLUSTER_LIGHT_LOOP in Unity 6.1 and above.
            
            #pragma shader_feature_local _ _CONVERT_FROM_ROUGHNESS
            #pragma shader_feature_local _ _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _ _ALPHATEST_ON
            #pragma shader_feature_local_fragment _NOISE_TYPE_PERLIN _NOISE_TYPE_VRN_CENTER _NOISE_TYPE_VRN_EDGE
            #pragma shader_feature_local_fragment _ _REVERSE_DIRECTION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            #include "./NoiseFunctions.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float _Surface;
                float _Cutoff;
                float4 _BaseColor;
                float4 _BaseTexture_ST;
                float _NormalStrength;
                float _Metallic;
                float3 _SpecularColor;
                float _Smoothness;
                float _HeightMapStrength;
                float _OcclusionStrength;
                float3 _EmissionColor;
                float _NoiseScale;
                float _NoiseStrength;
                float _CutoffHeight;
                float3 _EdgeColor;
                float _EdgeThickness;
                float _CycleSpeed;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

#ifdef _SPECULAR_SETUP
            TEXTURE2D(_SpecularMap);
            SAMPLER(sampler_SpecularMap);
#else
            TEXTURE2D(_MetallicMap);
            SAMPLER(sampler_MetallicMap);
#endif

            TEXTURE2D(_SmoothnessMap);
            SAMPLER(sampler_SmoothnessMap);
            
            TEXTURE2D(_NormalTexture);
            SAMPLER(sampler_NormalTexture);
            
            TEXTURE2D(_HeightMap);
            SAMPLER(sampler_HeightMap);
            
            TEXTURE2D(_OcclusionMap);
            SAMPLER(sampler_OcclusionMap);
            
            TEXTURE2D(_EmissionMap);
            SAMPLER(sampler_EmissionMap);

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 dynamicLightmapUV : TEXCOORD2;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 positionOS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float3 viewWS : TEXCOORD4;
                float4 tangentWS : TEXCOORD5;
                float2 dynamicLightmapUV : TEXCOORD6;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionOS = v.positionOS;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);
                o.tangentWS = float4(TransformObjectToWorldDir(v.tangentOS.xyz), v.tangentOS.w);
                o.dynamicLightmapUV = v.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;

                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            {
                // Set up parallax UVs.
                float3 viewDirWS = normalize(i.viewWS);
                float3 viewDirTS = GetViewDirectionTangentSpace(i.tangentWS, i.normalWS, viewDirWS);
                
                i.uv += ParallaxMapping(TEXTURE2D_ARGS(_HeightMap, sampler_HeightMap), viewDirTS, _HeightMapStrength, i.uv);
                
                // Set up surface data.
                SurfaceData surfaceData = (SurfaceData)0;
                
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv) * _BaseColor;
                surfaceData.albedo = baseColor.rgb;
                surfaceData.alpha = baseColor.a;
                
                AlphaDiscard(surfaceData.alpha, _Cutoff);
                
#ifdef _NOISE_TYPE_PERLIN
                float noise = (perlinNoise(i.uv, _NoiseScale, _Time.y * _CycleSpeed) - 0.5f) * _NoiseStrength;
#else
                float distFromCenter, distFromEdge;
                voronoiNoise(i.uv, _NoiseScale, distFromCenter, distFromEdge, _Time.y * _CycleSpeed);
                
#ifdef _NOISE_TYPE_VRN_CENTER
                float noise = (distFromCenter - 0.5f) * _NoiseStrength;
#else
                float noise = (distFromEdge - 0.5f) * _NoiseStrength;
#endif
                
#endif
                
                float height = i.positionOS.y + noise;
                
#ifdef _REVERSE_DIRECTION
                AlphaDiscard(height, _CutoffHeight);
#else
                AlphaDiscard(_CutoffHeight,height);
#endif
                
#ifdef _SPECULAR_SETUP
                surfaceData.metallic = 0.0f;
                surfaceData.specular = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, i.uv).rgb * _SpecularColor;
#else
                surfaceData.metallic = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.uv).r * _Metallic;
                surfaceData.specular = 0.0f;
#endif
                
#ifdef _CONVERT_FROM_ROUGHNESS
                surfaceData.smoothness = (1.0f - SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, i.uv).r) * _Smoothness;
#else
                surfaceData.smoothness = SAMPLE_TEXTURE2D(_SmoothnessMap, sampler_SmoothnessMap, i.uv).r * _Smoothness;
#endif
                
                surfaceData.occlusion = lerp(1.0f, SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, i.uv).r, _OcclusionStrength);
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTexture, sampler_NormalTexture, i.uv), _NormalStrength);
                surfaceData.normalTS = normalize(normalTS);
                surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv).rgb * _EmissionColor;
                
#ifdef _REVERSE_DIRECTION
                float edge = step(height, _CutoffHeight + _EdgeThickness);
#else
                float edge = step(_CutoffHeight - _EdgeThickness, height);
#endif
                
                surfaceData.emission += edge * _EdgeColor;
                
                // Set up input data.
                InputData inputData = (InputData)0;
                
                inputData.positionCS = i.positionCS;
                inputData.positionWS = i.positionWS;
                
                float3 normalWS = NormalizeNormalPerPixel(i.normalWS);
                float3 bitangent = cross(normalWS.xyz, i.tangentWS.xyz) * i.tangentWS.w * unity_WorldTransformParams.w;
                inputData.tangentToWorld = float3x3(i.tangentWS.xyz, bitangent.xyz, normalWS.xyz);
                
                inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, inputData.tangentToWorld);
                inputData.viewDirectionWS = viewDirWS;
                inputData.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(i.dynamicLightmapUV);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
                
                // Calculate final PBR-lit color.
                float4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));
                
                return color;
            }

            ENDHLSL
        }

        // ShadowCaster pass added in Part 6.

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            Cull [_Cull]
            ZTest LEqual
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex shadowPassVert
            #pragma fragment shadowPassFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "./NoiseFunctions.hlsl"

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature_local_fragment _ _ALPHATEST_ON
            #pragma shader_feature_local_fragment _NOISE_TYPE_PERLIN _NOISE_TYPE_VRN_CENTER _NOISE_TYPE_VRN_EDGE
            #pragma shader_feature_local_fragment _ _REVERSE_DIRECTION
            
            CBUFFER_START(UnityPerMaterial)
                float _Surface;
                float _Cutoff;
                float4 _BaseColor;
                float4 _BaseTexture_ST;
                float _NormalStrength;
                float _Metallic;
                float3 _SpecularColor;
                float _Smoothness;
                float _HeightMapStrength;
                float _OcclusionStrength;
                float3 _EmissionColor;
                float _NoiseScale;
                float _NoiseStrength;
                float _CutoffHeight;
                float3 _EdgeColor;
                float _EdgeThickness;
                float _CycleSpeed;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            float3 _LightDirection;
            float3 _LightPosition;

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionOS : TEXCOORD1;
            };

            float4 GetShadowPositionHClip(float3 positionOS, float3 normalOS)
            {
                float3 positionWS = TransformObjectToWorld(positionOS);
                float3 normalWS = TransformObjectToWorldNormal(normalOS);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
                float3 lightDirectionWS = _LightDirection;
#endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                positionCS = ApplyShadowClamping(positionCS);

                return positionCS;
            }

            v2f shadowPassVert(appdata v)
            {
                v2f o = (v2f)0;

                o.positionCS = GetShadowPositionHClip(v.positionOS.xyz, v.normalOS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);
                o.positionOS = v.positionOS;

                return o;
            }

            float4 shadowPassFrag(v2f i) : SV_TARGET
            {
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv) * _BaseColor;
                AlphaDiscard(baseColor.a, _Cutoff);
                
#ifdef _NOISE_TYPE_PERLIN
                float noise = (perlinNoise(i.uv, _NoiseScale, _Time.y * _CycleSpeed) - 0.5f) * _NoiseStrength;
#else
                float distFromCenter, distFromEdge;
                voronoiNoise(i.uv, _NoiseScale, distFromCenter, distFromEdge, _Time.y * _CycleSpeed);
                
#ifdef _NOISE_TYPE_VRN_CENTER
                float noise = (distFromCenter - 0.5f) * _NoiseStrength;
#else
                float noise = (distFromEdge - 0.5f) * _NoiseStrength;
#endif
                
#endif
                
                float height = i.positionOS.y + noise;
                
#ifdef _REVERSE_DIRECTION
                AlphaDiscard(height, _CutoffHeight);
#else
                AlphaDiscard(_CutoffHeight,height);
#endif
                
                return 0;
            }

            ENDHLSL
        }

        // DepthOnly and DepthNormals passes added in Part 4.

        Pass
        {
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            Cull [_Cull]
            ZTest LEqual
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma vertex depthOnlyVert
            #pragma fragment depthOnlyFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./NoiseFunctions.hlsl"
            
            #pragma shader_feature_local_fragment _ _ALPHATEST_ON
            #pragma shader_feature_local_fragment _NOISE_TYPE_PERLIN _NOISE_TYPE_VRN_CENTER _NOISE_TYPE_VRN_EDGE
            #pragma shader_feature_local_fragment _ _REVERSE_DIRECTION
            
            CBUFFER_START(UnityPerMaterial)
                float _Surface;
                float _Cutoff;
                float4 _BaseColor;
                float4 _BaseTexture_ST;
                float _NormalStrength;
                float _Metallic;
                float3 _SpecularColor;
                float _Smoothness;
                float _HeightMapStrength;
                float _OcclusionStrength;
                float3 _EmissionColor;
                float _NoiseScale;
                float _NoiseStrength;
                float _CutoffHeight;
                float3 _EdgeColor;
                float _EdgeThickness;
                float _CycleSpeed;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionOS : TEXCOORD1;
            };

            v2f depthOnlyVert(appdata v)
            {
                v2f o = (v2f)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);
                o.positionOS = v.positionOS;

                return o;
            }

            float depthOnlyFrag(v2f i) : SV_TARGET
            {
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv) * _BaseColor;
                AlphaDiscard(baseColor.a, _Cutoff);
                
#ifdef _NOISE_TYPE_PERLIN
                float noise = (perlinNoise(i.uv, _NoiseScale, _Time.y * _CycleSpeed) - 0.5f) * _NoiseStrength;
#else
                float distFromCenter, distFromEdge;
                voronoiNoise(i.uv, _NoiseScale, distFromCenter, distFromEdge, _Time.y * _CycleSpeed);
                
#ifdef _NOISE_TYPE_VRN_CENTER
                float noise = (distFromCenter - 0.5f) * _NoiseStrength;
#else
                float noise = (distFromEdge - 0.5f) * _NoiseStrength;
#endif
                
#endif
                
                float height = i.positionOS.y + noise;
                
#ifdef _REVERSE_DIRECTION
                AlphaDiscard(height, _CutoffHeight);
#else
                AlphaDiscard(_CutoffHeight,height);
#endif
                
                return i.positionCS.z;
            }

            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            Cull [_Cull]
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            #pragma vertex depthNormalsVert
            #pragma fragment depthNormalsFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./NoiseFunctions.hlsl"
            
            #pragma shader_feature_local_fragment _ _ALPHATEST_ON
            #pragma shader_feature_local_fragment _NOISE_TYPE_PERLIN _NOISE_TYPE_VRN_CENTER _NOISE_TYPE_VRN_EDGE
            #pragma shader_feature_local_fragment _ _REVERSE_DIRECTION

            CBUFFER_START(UnityPerMaterial)
                float _Surface;
                float _Cutoff;
                float4 _BaseColor;
                float4 _BaseTexture_ST;
                float _NormalStrength;
                float _Metallic;
                float3 _SpecularColor;
                float _Smoothness;
                float _HeightMapStrength;
                float _OcclusionStrength;
                float3 _EmissionColor;
                float _NoiseScale;
                float _NoiseStrength;
                float _CutoffHeight;
                float3 _EdgeColor;
                float _EdgeThickness;
                float _CycleSpeed;
            CBUFFER_END
            
            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            TEXTURE2D(_NormalTexture);
            SAMPLER(sampler_NormalTexture);

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float4 positionOS : TEXCOORD3;
            };

            v2f depthNormalsVert(appdata v)
            {
                v2f o = (v2f)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTexture);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.normalWS = NormalizeNormalPerVertex(normalWS);
                o.tangentWS = float4(TransformObjectToWorldDir(v.tangentOS.xyz), v.tangentOS.w);
                o.positionOS = v.positionOS;

                return o;
            }

            float4 depthNormalsFrag(v2f i) : SV_TARGET
            {
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, i.uv) * _BaseColor;
                AlphaDiscard(baseColor.a, _Cutoff);
                
#ifdef _NOISE_TYPE_PERLIN
                float noise = (perlinNoise(i.uv, _NoiseScale, _Time.y * _CycleSpeed) - 0.5f) * _NoiseStrength;
#else
                float distFromCenter, distFromEdge;
                voronoiNoise(i.uv, _NoiseScale, distFromCenter, distFromEdge, _Time.y * _CycleSpeed);
                
#ifdef _NOISE_TYPE_VRN_CENTER
                float noise = (distFromCenter - 0.5f) * _NoiseStrength;
#else
                float noise = (distFromEdge - 0.5f) * _NoiseStrength;
#endif
                
#endif
                
                float height = i.positionOS.y + noise;
                
#ifdef _REVERSE_DIRECTION
                AlphaDiscard(height, _CutoffHeight);
#else
                AlphaDiscard(_CutoffHeight,height);
#endif
                
                float3 normalWS = NormalizeNormalPerPixel(i.normalWS);

                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalTexture, sampler_NormalTexture, i.uv), _NormalStrength);

                float3 binormalWS = cross(normalWS, i.tangentWS.xyz) * i.tangentWS.w * unity_WorldTransformParams.w;
                normalWS = normalize(
                    normalTS.x * i.tangentWS.xyz +
                    normalTS.y * binormalWS +
                    normalTS.z * normalWS);

                return float4(normalWS, 0.0f);
            }

            ENDHLSL
        }
    }

    CustomEditor "ShaderBasics.Editor.DissolveShaderGUI"
}

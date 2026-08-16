using System;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderBasics.Editor
{
    public class PBRShaderGUI : ShaderGUI
    {
        //
        // The PBRShaderProperty and enum declarations were moved to ShaderGUITypes.cs as they are reused in new scripts.
        //
        
        private string[] surfaceTypeNames = Enum.GetNames(typeof(SurfaceType));
        private string[] renderFaceNames = Enum.GetNames(typeof(RenderFace));
        private string[] blendFunctionNames = Enum.GetNames(typeof(BlendFunction));
        private string[] zWriteControlNames = Enum.GetNames(typeof(ZWriteControl));
        private string[] queueControlNames =  Enum.GetNames(typeof(QueueControl));
        private string[] compareFunctionNames = Enum.GetNames(typeof(CompareFunction));

        private PBRShaderProperty baseColor = new("_BaseColor", "Base Color", 
            "Albedo color of the object.");
        private PBRShaderProperty baseTexture = new("_BaseTexture", "Base Texture", 
            "Albedo color of the object.");
        private PBRShaderProperty useSpecularSetup = new("_UseSpecularSetup", "Use Specular Setup", 
            "Should the shader use Specular workflow (instead of Metallic workflow)?");
        private PBRShaderProperty metallicMap = new("_MetallicMap", "Metallic Map", 
            "How metallic the object's surface is (only used in metallic workflow mode).");
        private PBRShaderProperty metallic = new("_Metallic", "Metallic", 
            "How metallic the object's surface is (only used in metallic workflow mode).");
        private PBRShaderProperty specularMap = new("_SpecularMap", "Specular Map", 
            "The color of the object's specular highlights (only used in specular workflow mode).");
        private PBRShaderProperty specularColor = new("_SpecularColor", "Specular Color", 
            "The color of the object's specular highlights (only used in specular workflow mode).");
        private PBRShaderProperty smoothnessMap = new("_SmoothnessMap", "Smoothness Map", 
            "How smooth (or rough) the microscopic surface of the object is.");
        private PBRShaderProperty smoothness = new("_Smoothness", "Smoothness", 
            "How smooth (or rough) the microscopic surface of the object is.");
        private PBRShaderProperty convertFromRoughness = new("_ConvertFromRoughness", "Convert From Roughness", 
            "Should the shader treat the smoothness texture as a roughness texture instead?");
        private PBRShaderProperty normalTexture = new("_NormalTexture", "Normal Texture", 
            "A texture encoding normal vector offsets at each point on the object surface.");
        private PBRShaderProperty normalStrength = new("_NormalStrength", "Normal Strength", 
            "How strongly the normal texture is applied to the existing surface normals.");
        private PBRShaderProperty heightMap = new("_HeightMap", "Height Map", 
            "The physical height offset of each part of the surface.");
        private PBRShaderProperty heightMapStrength = new("_HeightMapStrength", "Height Map Strength", 
            "How strongly the height map values are applied as UV offsets to create a surface height illusion.");
        private PBRShaderProperty occlusionMap = new("_OcclusionMap", "Occlusion Map", 
            "The strength of ambient occlusion at each point on the surface.");
        private PBRShaderProperty occlusionStrength = new("_OcclusionStrength", "Occlusion Strength", 
            "How strongly the occlusion map values are applied to the surface.");
        private PBRShaderProperty emissionMap = new("_EmissionMap", "Emission Map", 
            "The color of emissive (self-illuminated) light on the surface.");
        private PBRShaderProperty emissionColor = new("_EmissionColor", "Emission Color", 
            "The color of emissive (self-illuminated) light on the surface.");
        
        private PBRShaderProperty surface = new("_Surface", "Surface Type", 
            "Choose whether to use opaque or transparent rendering mode.");
        private PBRShaderProperty cutoff = new("_Cutoff", "Alpha Cutoff", 
            "Pixels with alpha below this threshold value get discarded.");
        private PBRShaderProperty srcBlend = new("_SrcBlend", "Source Blend", 
            "Blend factor to use for the existing framebuffer RGB contents.");
        private PBRShaderProperty dstBlend = new("_DstBlend", "Destination Blend", 
            "Blend factor to use for the newly drawn object RGB contents.");
        private PBRShaderProperty srcBlendAlpha = new("_SrcBlendAlpha", "Source Blend Alpha", 
            "Blend factor to use for the existing framebuffer alpha contents.");
        private PBRShaderProperty dstBlendAlpha = new("_DstBlendAlpha", "Destination Blend Alpha", 
            "Blend factor to use for the newly drawn object alpha contents.");
        private PBRShaderProperty zWrite = new("_ZWrite", "ZWrite", 
            "Should this material write depth information?");
        private PBRShaderProperty zTest = new("_ZTest", "ZTest", 
            "Choose which depth test to apply to this object.");
        private PBRShaderProperty cull = new("_Cull", "Render Face", 
            "Which faces should the shader draw?");
        private PBRShaderProperty alphaToMask = new("_AlphaToMask", "Alpha To Mask", 
            "Should the shader use alpha-to-mask if MSAA is enabled?");
        
        private PBRShaderProperty castShadows = new("_CastShadows", "Cast Shadows", 
            "Should the object cast shadows from realtime lights?");
        private PBRShaderProperty receiveShadows = new("_ReceiveShadows", "Receive Shadows", 
            "Should the object receive shadows from realtime lights?");
        private PBRShaderProperty blend = new("_Blend", "Blend Mode", 
            "Choose which blending function to use for transparent objects.");
        private PBRShaderProperty alphaClip = new("_AlphaClip", "Alpha Clipping", 
            "Choose whether to use alpha clipping. Note that the threshold value may be set within the graph itself.");
        private PBRShaderProperty zWriteControl = new("_ZWriteControl", "ZWrite Control", 
            "Choose whether to handle ZWrite automatically, or force it on or off at all times.");
        private PBRShaderProperty queueOffset = new("_QueueOffset", "Sorting Priority", 
            "Determines chronological rendering order for a Material. Materials with lower value are rendered first.");
        private PBRShaderProperty queueControl = new("_QueueControl", "Queue Control", 
            "Controls whether render queue is set based on material surface type, or explicitly set by the user.");

        private const string alphaTestKeyword = "_ALPHATEST_ON";
        private const string receiveShadowsOffKeyword = "_RECEIVE_SHADOWS_OFF";
        private const string transparentSurfaceKeyword = "_SURFACE_TYPE_TRANSPARENT";
        private const string renderTypeTag = "RenderType";
        private const string renderTypeOpaqueValue = "Opaque";
        private const string renderTypeTransparentValue = "Transparent";
        private const string renderTypeAlphaTestValue = "TransparentCutout";
        private const string shadowCasterPassName = "ShadowCaster";
        private const string depthOnlyPassName = "DepthOnly";
        protected const string missingEditorText = "No MaterialEditor found (PBRShaderGUI).";
        
        private const int queueOffsetRange = 50;

        protected readonly MaterialHeaderScopeList materialScopeList = new();
        protected MaterialEditor materialEditor;
        protected bool firstTimeOpen = true;

        protected virtual void FindProperties(MaterialProperty[] props)
        {
            baseColor.prop = FindProperty(baseColor.name, props, true);
            baseTexture.prop = FindProperty(baseTexture.name, props, true);
            
            useSpecularSetup.prop = FindProperty(useSpecularSetup.name, props, true);
            metallicMap.prop = FindProperty(metallicMap.name, props, true);
            metallic.prop = FindProperty(metallic.name, props, true);
            specularMap.prop = FindProperty(specularMap.name, props, true);
            specularColor.prop = FindProperty(specularColor.name, props, true);
            smoothnessMap.prop = FindProperty(smoothnessMap.name, props, true);
            smoothness.prop = FindProperty(smoothness.name, props, true);
            convertFromRoughness.prop = FindProperty(convertFromRoughness.name, props, true);
            normalTexture.prop = FindProperty(normalTexture.name, props, true);
            normalStrength.prop = FindProperty(normalStrength.name, props, true);
            heightMap.prop = FindProperty(heightMap.name, props, true);
            heightMapStrength.prop = FindProperty(heightMapStrength.name, props, true);
            occlusionMap.prop = FindProperty(occlusionMap.name, props, true);
            occlusionStrength.prop = FindProperty(occlusionStrength.name, props, true);
            emissionMap.prop = FindProperty(emissionMap.name, props, true);
            emissionColor.prop = FindProperty(emissionColor.name, props, true);
            
            surface.prop = FindProperty(surface.name, props, true);
            cutoff.prop = FindProperty(cutoff.name, props, true);
            srcBlend.prop = FindProperty(srcBlend.name, props, true);
            dstBlend.prop = FindProperty(dstBlend.name, props, true);
            srcBlendAlpha.prop = FindProperty(srcBlendAlpha.name, props, true);
            dstBlendAlpha.prop = FindProperty(dstBlendAlpha.name, props, true);
            zWrite.prop = FindProperty(zWrite.name, props, true);
            zTest.prop = FindProperty(zTest.name, props, true);
            cull.prop = FindProperty(cull.name, props, true);
            alphaToMask.prop = FindProperty(alphaToMask.name, props, true);
            
            castShadows.prop = FindProperty(castShadows.name, props, true);
            receiveShadows.prop = FindProperty(receiveShadows.name, props, true);
            blend.prop = FindProperty(blend.name, props, true);
            alphaClip.prop = FindProperty(alphaClip.name, props, true);
            zWriteControl.prop = FindProperty(zWriteControl.name, props, true);
            queueOffset.prop = FindProperty(queueOffset.name, props, true);
            queueControl.prop = FindProperty(queueControl.name, props, true);
        }
        
        protected void SetBlendMode(BlendFunction blendFunction, SurfaceType surfaceType, Material material)
        {
            var srcBlendRGB = BlendMode.One;
            var dstBlendRGB = BlendMode.Zero;
            var srcBlendA = BlendMode.One;
            var dstBlendA = BlendMode.Zero;

            if (surfaceType == SurfaceType.Transparent)
            {
                switch (blendFunction)
                {
                    case BlendFunction.Alpha:
                    {
                        srcBlendRGB = BlendMode.SrcAlpha;
                        dstBlendRGB = BlendMode.OneMinusSrcAlpha;
                        srcBlendA = BlendMode.One;
                        dstBlendA = BlendMode.OneMinusSrcAlpha;
                        break;
                    }
                    case BlendFunction.Premultiply:
                    {
                        srcBlendRGB = BlendMode.One;
                        dstBlendRGB = BlendMode.OneMinusSrcAlpha;
                        srcBlendA = BlendMode.One;
                        dstBlendA = BlendMode.OneMinusSrcAlpha;
                        break;
                    }
                    case BlendFunction.Additive:
                    {
                        srcBlendRGB = BlendMode.SrcAlpha;
                        dstBlendRGB = BlendMode.One;
                        srcBlendA = BlendMode.One;
                        dstBlendA = BlendMode.One;
                        break;
                    }
                    case BlendFunction.Multiply:
                    {
                        srcBlendRGB = BlendMode.DstColor;
                        dstBlendRGB = BlendMode.Zero;
                        srcBlendA = BlendMode.Zero;
                        dstBlendA = BlendMode.One;
                        break;
                    }
                }
            }

            material.SetFloat(srcBlend.id, (float)srcBlendRGB);
            material.SetFloat(dstBlend.id, (float)dstBlendRGB);
            material.SetFloat(srcBlendAlpha.id, (float)srcBlendA);
            material.SetFloat(dstBlendAlpha.id, (float)dstBlendA);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            if (materialEditor == null)
            {
                throw new ArgumentNullException(missingEditorText);
            }

            this.materialEditor = materialEditor;
            var material = materialEditor.target as Material;

            FindProperties(properties);

            if (firstTimeOpen)
            {
                materialScopeList.RegisterHeaderScope(new GUIContent("Surface Options"), 1u << 0, DrawSurfaceProperties);
                materialScopeList.RegisterHeaderScope(new GUIContent("PBR Inputs"), 1u << 1, DrawPBRProperties);
                materialScopeList.RegisterHeaderScope(new GUIContent("Advanced Options"), 1u << 2, DrawAdvancedSettings);
                firstTimeOpen = false;
            }

            materialScopeList.DrawHeaders(materialEditor, material);
            materialEditor.serializedObject.ApplyModifiedProperties();
        }

        protected void DrawSurfaceProperties(Material material)
        {
            materialEditor.PopupShaderProperty(surface.prop, surface.info, surfaceTypeNames);
            var surfaceTypeValue = (SurfaceType)material.GetFloat(surface.id);
        
            if (surfaceTypeValue == SurfaceType.Transparent)
            {
                materialEditor.PopupShaderProperty(blend.prop, blend.info, blendFunctionNames);
            }
        
            var blendFuncValue = (BlendFunction)material.GetFloat(blend.id);
            
            materialEditor.PopupShaderProperty(cull.prop, cull.info, renderFaceNames);
            materialEditor.PopupShaderProperty(zWriteControl.prop, zWriteControl.info, zWriteControlNames);
            materialEditor.PopupShaderProperty(zTest.prop, zTest.info, compareFunctionNames);

            var alphaClipValue = material.GetFloat(alphaClip.id) > 0.5f;
            
            EditorGUI.BeginChangeCheck();
            alphaClipValue = EditorGUILayout.Toggle(alphaClip.info, alphaClipValue);
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(material, "Toggle Alpha Clipping");
                material.SetFloat(alphaClip.id, alphaClipValue ? 1.0f : 0.0f);
            }

            if (alphaClipValue)
            {
                EditorGUI.indentLevel++;
                materialEditor.ShaderProperty(cutoff.prop, cutoff.info);
                EditorGUI.indentLevel--;
            }
            
            // Set render type, blend modes, depth write/test, etc based on material property values.
            bool useAlphaToMask = false;
            int renderQueueValue = material.shader.renderQueue;
            bool useZWrite = false;
            
            if (surfaceTypeValue == SurfaceType.Opaque)
            {
                SetBlendMode(blendFuncValue, surfaceTypeValue, material);
                useZWrite = true;
                material.DisableKeyword(transparentSurfaceKeyword);

                if (alphaClipValue)
                {
                    material.EnableKeyword(alphaTestKeyword);
                    renderQueueValue = (int)RenderQueue.AlphaTest;
                    material.SetOverrideTag(renderTypeTag, renderTypeAlphaTestValue);
                    useAlphaToMask = true;
                }
                else
                {
                    material.DisableKeyword(alphaTestKeyword);
                    renderQueueValue = (int)RenderQueue.Geometry;
                    material.SetOverrideTag(renderTypeTag, renderTypeOpaqueValue);
                }
            }
            else
            {
                material.SetOverrideTag(renderTypeTag, renderTypeTransparentValue);
                SetBlendMode(blendFuncValue, surfaceTypeValue, material);
                useZWrite = false;
                renderQueueValue = (int)RenderQueue.Transparent;
                material.EnableKeyword(transparentSurfaceKeyword);

                if (alphaClipValue)
                {
                    material.EnableKeyword(alphaTestKeyword);
                }
                else
                {
                    material.DisableKeyword(alphaTestKeyword);
                }
            }

            material.SetFloat(alphaToMask.id, useAlphaToMask ? 1.0f : 0.0f);
            
            // Override auto depth write values if needed.
            var useZWriteControl = (ZWriteControl)material.GetFloat(zWriteControl.id);

            if (useZWriteControl == ZWriteControl.ForceEnabled)
            {
                useZWrite = true;
            }
            else if (useZWriteControl == ZWriteControl.ForceDisabled)
            {
                useZWrite = false;
            }
        
            material.SetFloat(zWrite.id, useZWrite ? 1.0f : 0.0f);
            material.SetShaderPassEnabled(depthOnlyPassName, useZWrite);
            
            // When using sorting priority, offset the render queue value.
            if (material.GetFloat(queueControl.id) == (float)QueueControl.Auto)
            {
                renderQueueValue += (int)material.GetFloat(queueOffset.id);
                material.renderQueue = renderQueueValue;
            }
            
            // Display cast shadows toggle and toggle shadow caster pass accordingly.
            bool castShadowsValue = material.GetFloat(castShadows.id) > 0.5f;

            EditorGUI.BeginChangeCheck();
            {
                castShadowsValue = EditorGUILayout.Toggle(castShadows.info, castShadowsValue);
            }
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(material, "Toggle Cast Shadows");
                material.SetFloat(castShadows.id, castShadowsValue ? 1.0f : 0.0f);
                
                material.SetShaderPassEnabled(shadowCasterPassName, castShadowsValue);
            }
            
            // Display receive shadows toggle and toggle shadow caster pass accordingly.
            bool receiveShadowsValue = material.GetFloat(receiveShadows.id) > 0.5f;

            EditorGUI.BeginChangeCheck();
            {
                receiveShadowsValue = EditorGUILayout.Toggle(receiveShadows.info, receiveShadowsValue);
            }
            if (EditorGUI.EndChangeCheck())
            {
                Undo.RecordObject(material, "Toggle Receive Shadows");
                material.SetFloat(receiveShadows.id, receiveShadowsValue ? 1.0f : 0.0f);
                
                if (receiveShadowsValue)
                {
                    material.DisableKeyword(receiveShadowsOffKeyword);
                }
                else
                {
                    material.EnableKeyword(receiveShadowsOffKeyword);
                }
            }
        }

        protected void DrawPBRProperties(Material material)
        {
            materialEditor.TexturePropertySingleLine(baseTexture.info, baseTexture.prop, baseColor.prop);
            materialEditor.TextureScaleOffsetProperty(baseTexture.prop);
            
            materialEditor.ShaderProperty(useSpecularSetup.prop, useSpecularSetup.info);

            if (useSpecularSetup.prop.intValue > 0)
            {
                materialEditor.TexturePropertySingleLine(specularMap.info, specularMap.prop, specularColor.prop);
            }
            else
            {
                materialEditor.TexturePropertySingleLine(metallicMap.info, metallicMap.prop, metallic.prop);
            }
            
            materialEditor.TexturePropertySingleLine(smoothnessMap.info, smoothnessMap.prop, smoothness.prop);
            materialEditor.ShaderProperty(convertFromRoughness.prop, convertFromRoughness.info);
            materialEditor.TexturePropertySingleLine(normalTexture.info, normalTexture.prop, normalStrength.prop);
            materialEditor.TexturePropertySingleLine(heightMap.info, heightMap.prop, heightMapStrength.prop);
            materialEditor.TexturePropertySingleLine(occlusionMap.info, occlusionMap.prop, occlusionStrength.prop);
            materialEditor.TexturePropertySingleLine(emissionMap.info,  emissionMap.prop, emissionColor.prop);
        }
        
        protected void DrawAdvancedSettings(Material material)
        {
            // If auto queue is used, then use sorting priority field. Otherwise, let user set render queue freely.
            materialEditor.PopupShaderProperty(queueControl.prop, queueControl.info, queueControlNames);

            if(material.GetFloat(queueControl.id) == (float)QueueControl.UserOverride)
            {
                materialEditor.RenderQueueField();
            }
            else
            {
                materialEditor.IntSliderShaderProperty(queueOffset.prop, -queueOffsetRange, queueOffsetRange, queueOffset.info);
            }
        }
    }
}

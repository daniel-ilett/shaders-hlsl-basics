using System;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderBasics.Editor
{
    public class DissolveShaderGUI : PBRShaderGUI
    {
        private enum NoiseType 
        {
            Perlin = 0,
            VoronoiCenter = 1,
            VoronoiEdge = 2
        }
        
        private string[] noiseTypeNames = Enum.GetNames(typeof(NoiseType));
        
        private PBRShaderProperty noiseScale = new("_NoiseScale", "Noise Scale", "");
        private PBRShaderProperty noiseStrength = new("_NoiseStrength", "Noise Strength", "");
        private PBRShaderProperty cutoffHeight = new("_CutoffHeight",  "Cutoff Height", "");
        private PBRShaderProperty edgeColor = new("_EdgeColor", "Edge Color", "");
        private PBRShaderProperty edgeThickness = new("_EdgeThickness", "Edge Thickness", "");
        private PBRShaderProperty cycleSpeed = new("_CycleSpeed", "Cycle Speed", "");
        private PBRShaderProperty noiseType = new("_NoiseType", "Noise Type", "");
        private PBRShaderProperty reverseDirection = new("_ReverseDirection", "Reverse Direction", "");
        private PBRShaderProperty useHeightCutoff = new("_UseHeightCutoff", "Add Noise To Height", "");

        protected override void FindProperties(MaterialProperty[] props)
        {
            base.FindProperties(props);

            noiseScale.prop = FindProperty(noiseScale.name, props, true);
            noiseStrength.prop = FindProperty(noiseStrength.name, props, true);
            cutoffHeight.prop = FindProperty(cutoffHeight.name, props, true);
            edgeColor.prop = FindProperty(edgeColor.name, props, true);
            edgeThickness.prop = FindProperty(edgeThickness.name, props, true);
            cycleSpeed.prop = FindProperty(cycleSpeed.name, props, true);
            
            noiseType.prop = FindProperty(noiseType.name, props, false);
            reverseDirection.prop = FindProperty(reverseDirection.name, props, false);
            useHeightCutoff.prop = FindProperty(useHeightCutoff.name, props, false);
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
                materialScopeList.RegisterHeaderScope(new GUIContent("Dissolve Properties"), 1u << 2, DrawDissolveProperties);
                materialScopeList.RegisterHeaderScope(new GUIContent("Advanced Options"), 1u << 3, DrawAdvancedSettings);
                firstTimeOpen = false;
            }

            materialScopeList.DrawHeaders(materialEditor, material);
            materialEditor.serializedObject.ApplyModifiedProperties();
        }

        private void DrawDissolveProperties(Material material)
        {
            materialEditor.ShaderProperty(noiseScale.prop, noiseScale.info);
            materialEditor.ShaderProperty(noiseStrength.prop, noiseStrength.info);

            if (useHeightCutoff.prop != null)
            {
                materialEditor.ShaderProperty(useHeightCutoff.prop, useHeightCutoff.info);
            }
            
            materialEditor.ShaderProperty(cutoffHeight.prop, cutoffHeight.info);
            materialEditor.ShaderProperty(edgeColor.prop, edgeColor.info);
            materialEditor.ShaderProperty(edgeThickness.prop, edgeThickness.info);
            materialEditor.ShaderProperty(cycleSpeed.prop, cycleSpeed.info);

            if (noiseType.prop != null)
            {
                var noiseTypeValue = (NoiseType)material.GetFloat(noiseType.id);
                
                EditorGUI.BeginChangeCheck();
                noiseTypeValue = (NoiseType)EditorGUILayout.EnumPopup(noiseType.info, noiseTypeValue);
                if (EditorGUI.EndChangeCheck())
                {
                    Undo.RecordObject(material, "Change Noise Type");
                    material.SetFloat(noiseType.id, (float)noiseTypeValue);

                    if (noiseTypeValue == NoiseType.Perlin)
                    {
                        material.EnableKeyword("_NOISE_TYPE_PERLIN");
                        material.DisableKeyword("_NOISE_TYPE_VRN_CENTER");
                        material.DisableKeyword("_NOISE_TYPE_VRN_EDGE");
                    }
                    else if (noiseTypeValue == NoiseType.VoronoiCenter)
                    {
                        material.DisableKeyword("_NOISE_TYPE_PERLIN");
                        material.EnableKeyword("_NOISE_TYPE_VRN_CENTER");
                        material.DisableKeyword("_NOISE_TYPE_VRN_EDGE");
                    }
                    else
                    {
                        material.DisableKeyword("_NOISE_TYPE_PERLIN");
                        material.DisableKeyword("_NOISE_TYPE_VRN_CENTER");
                        material.EnableKeyword("_NOISE_TYPE_VRN_EDGE");
                    }
                }
                
                materialEditor.ShaderProperty(reverseDirection.prop, reverseDirection.info);
            }
        }
    }
}

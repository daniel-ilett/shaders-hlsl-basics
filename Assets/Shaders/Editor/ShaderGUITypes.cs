using UnityEditor;
using UnityEngine;

namespace ShaderBasics.Editor
{
    public struct PBRShaderProperty
    {
        public MaterialProperty prop;
        public readonly string name;
        public readonly GUIContent info;
        public readonly int id;

        public PBRShaderProperty(string name, string label, string desc)
        {
            prop = null;
            this.name = name;
            info = new GUIContent(label, desc);
            id = Shader.PropertyToID(name);
        }
    }
        
    public enum SurfaceType
    {
        Opaque = 0,
        Transparent = 1
    }

    public enum RenderFace
    {
        Front = 2,
        Back = 1,
        Both = 0
    }

    public enum BlendFunction
    {
        Alpha = 0,
        Premultiply = 1,
        Additive = 2,
        Multiply = 3
    }

    public enum ZWriteControl
    {
        Auto = 0,
        ForceEnabled = 1,
        ForceDisabled = 2
    }

    public enum QueueControl
    {
        Auto = 0,
        UserOverride = 1
    }
}

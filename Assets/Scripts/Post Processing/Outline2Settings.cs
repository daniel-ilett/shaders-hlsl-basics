using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("Basics/Outline 2")]
public class Outline2Settings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter strength = new(0.0f, 0.0f, 1.0f);
    public ColorParameter outlineColor = new(Color.black);
    public ClampedFloatParameter colorThreshold = new(0.9f, 0.0f, 1.0f);
    public ClampedFloatParameter depthThreshold = new(0.9f, 0.0f, 2.0f);
    public ClampedFloatParameter normalThreshold = new(0.9f, 0.0f, 2.0f);
    
    public bool IsActive()
    {
        return strength.value > 0.0f && active;
    }
}

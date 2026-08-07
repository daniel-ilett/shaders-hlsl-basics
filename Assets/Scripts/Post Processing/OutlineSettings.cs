using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("Basics/Outline")]
public class OutlineSettings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter strength = new(0.0f, 0.0f, 1.0f);
    public ColorParameter outlineColor = new(Color.black);
    public ClampedFloatParameter colorThreshold = new(0.9f, 0.0f, 1.0f);
    
    public bool IsActive()
    {
        return strength.value > 0.0f && active;
    }
}

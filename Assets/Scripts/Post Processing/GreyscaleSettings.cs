using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("Basics/Greyscale")]
public class GreyscaleSettings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter strength = new(0.0f, 0.0f, 1.0f);
    
    public bool IsActive()
    {
        return strength.value > 0.0f && active;
    }
}

using UnityEngine;
using UnityEngine.Rendering;

[System.Serializable, VolumeComponentMenu("Basics/Silhouette")]
public class SilhouetteSettings : VolumeComponent, IPostProcessComponent
{
    public BoolParameter enabled = new BoolParameter(false);
    public ColorParameter nearColor = new(Color.black);
    public ColorParameter farColor = new(Color.white);
    public ClampedFloatParameter depthPower = new(1.0f, 0.0f, 10.0f);
    
    public bool IsActive()
    {
        return enabled.value && active;
    }
}

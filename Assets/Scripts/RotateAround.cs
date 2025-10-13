using UnityEngine;
using UnityEngine.Rendering;

public class RotateAround : MonoBehaviour
{
    public float radius;
    public float yOffset;
    public Transform centerPoint;
    public float speed;

    private void Update()
    {
        float x = Mathf.Cos(Time.time * speed) * radius;
        float y = Mathf.Sin(Time.time * speed) * radius;

        transform.position = centerPoint.position + new Vector3(x, yOffset, y);
        transform.LookAt(centerPoint);
    }
}

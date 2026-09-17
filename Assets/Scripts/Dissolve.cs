using System;
using UnityEngine;

public class Dissolve : MonoBehaviour
{
    [SerializeField] private float speed;
    [SerializeField] private float offset;
    [SerializeField] private float height;
    [SerializeField] private float strength;
    [SerializeField] private new Renderer renderer;

    private Material material;

    private void Start()
    {
        material = renderer.material;
    }

    private void Update()
    {
        float t = Mathf.Sin(Time.time * speed + offset) * strength;

        material.SetFloat("_CutoffHeight", t + height);
    }
}

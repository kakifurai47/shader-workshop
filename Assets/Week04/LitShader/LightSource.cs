using System.Collections;
using System.Collections.Generic;
using UnityEngine;



[ExecuteInEditMode]
public class LightSource : MonoBehaviour
{
    public static bool dirty { get; private set; } = true;

    public Vector3 position;
    public Quaternion rotation;

    public LightType type;
    public Color color;
    public float intensity;
    public float range;
    public float innerAngle;
    public float outerAngle;

    Light data;

    public static void OnGPULightingSubmit() => dirty = false;

    void Update() {
        if (!data) return;

        bool _dirty = false;
        if(type       != data.type)           { type       = data.type;           _dirty = true; }
        if(color      != data.color)          { color      = data.color;          _dirty = true; }
        if(intensity  != data.intensity)      { intensity  = data.intensity;      _dirty = true; }
        if(range      != data.range)          { range      = data.range;          _dirty = true; }
        if(innerAngle != data.innerSpotAngle) { innerAngle = data.innerSpotAngle; _dirty = true; }
        if(outerAngle != data.spotAngle)      { outerAngle = data.spotAngle;      _dirty = true; }
        if(position   != transform.position)  { position   = transform.position;  _dirty = true; }
        if(rotation   != transform.rotation)  { rotation   = transform.rotation;  _dirty = true; }

        if (_dirty) {
            dirty = true;
        }
    }

    void OnEnable() {        
        data = GetComponent<Light>();
        if (!data) return;

        LightHub.instance.Register(this);
        dirty = true;
    }

    void OnDisable() {
        data = null;
        LightHub.instance.Unregister(this);
        dirty = true;
    }
}





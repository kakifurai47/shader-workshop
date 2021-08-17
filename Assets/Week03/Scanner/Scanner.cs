using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Scanner : MyPostProcessSimple
{
    static readonly int ScannerTransformID = Shader.PropertyToID("_ScannerTransform");

    public override void OnEnable() {
        Application.targetFrameRate = 60;
        base.OnEnable();
        var renderer = GetComponent<MeshRenderer>();
        renderer.material = postProcessMaterial;
    }

    void Update() {
        postProcessMaterial.SetVector(ScannerTransformID, transform.position);       
    }

}

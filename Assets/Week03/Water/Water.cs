using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Water : MonoBehaviour
{
    static readonly int waterLevelID = Shader.PropertyToID("_WaterLv");

    void Update() {
        Shader.SetGlobalFloat(waterLevelID, transform.position.y);
    }
}

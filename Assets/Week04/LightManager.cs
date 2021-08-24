using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEngine;

[ExecuteInEditMode]
public class LightManager : MonoBehaviour
{
    void Update() {
        var hub = LightHub.instance;
        if(hub == null) {
            return;
        }
        hub.OnUpdate();
    }
}

public class LightHub
{
    public static LightHub instance {
        get {
            if (m_instance == null) {
                m_instance = new LightHub();
            }
            return m_instance;
        }
    }
    static LightHub m_instance;
    static readonly int maxLightSourcePerType = 8;

    public void Register(LightSource src) {
        lights.Add(src);
    }

    public void Unregister(LightSource src) {
        lights.Remove(src);
    }

    public void OnUpdate() {
        if (!LightSource.dirty) return;

        System.Array.Clear(_dirLightBuffer, 0, _dirLightBuffer.Length);
        System.Array.Clear(_pntLightBuffer, 0, _pntLightBuffer.Length);
        System.Array.Clear(_sptLightBuffer, 0, _sptLightBuffer.Length);

        int dirLitCnt = 0;
        int pntLitCnt = 0;
        int sptLitCnt = 0;

        foreach(var light in lights) {
            var type = light.type;
        
            switch (type) {
                case LightType.Directional: AddDirLight(_dirLightBuffer, dirLitCnt, light); dirLitCnt++; break;   
                case LightType.Point:       AddPntLight(_pntLightBuffer, pntLitCnt, light); pntLitCnt++; break;
                case LightType.Spot:        AddSptLight(_sptLightBuffer, sptLitCnt, light); sptLitCnt++; break;
            }
        }

        Shader.SetGlobalFloat(pointLightBufferSizeID, pntLitCnt);
        Shader.SetGlobalFloat(spotLightBufferSizeID,  sptLitCnt);

        Shader.SetGlobalVectorArray(pointLightBufferID, _pntLightBuffer);
        Shader.SetGlobalVectorArray(spotLightBufferID,  _sptLightBuffer);

        LightSource.OnGPULightingSubmit();
    }

    void AddDirLight(Vector4[] buf, int index, LightSource src) {
        var direction = src.rotation.eulerAngles;
        var intensity = src.intensity;
        var color = src.color;

        buf[index * 2 + 0] = new Vector4(direction.x, direction.y, direction.z, intensity);
        buf[index * 2 + 1] = new Vector4(color.r, color.g, color.b, 0);
    }

    void AddPntLight(Vector4[] buf, int index, LightSource src) {
        var position  = src.position;
        var intensity = src.intensity;
        var color = src.color;
        var range = src.range;

        buf[index * 2 + 0] = new Vector4(position.x, position.y, position.z, intensity);
        buf[index * 2 + 1] = new Vector4(color.r, color.g, color.b, range);
    }

    void AddSptLight(Vector4[] buf, int index, LightSource src) {
        var position  = src.position;
        var range     = src.range;
        var direction = src.rotation * - Vector3.forward;
        var intensity = src.intensity;
        var color	  = src.color;
        var cosInner  = Mathf.Cos(src.innerAngle * Mathf.Deg2Rad / 2);        
        var cosOuter  = Mathf.Cos(src.outerAngle * Mathf.Deg2Rad / 2);
        var invAngDif = 1 / (cosInner - cosOuter + Mathf.Epsilon);

        buf[index * 4 + 0] = new Vector4(position.x, position.y, position.z, range);
        buf[index * 4 + 1] = new Vector4(direction.x, direction.y, direction.z, intensity);
        buf[index * 4 + 2] = new Vector4(color.r, color.g, color.b, cosOuter);
        buf[index * 4 + 3] = new Vector4(invAngDif, 0, 0, 0);
    }   

    int pointLightBufferSizeID = Shader.PropertyToID("my_pointLightSize");
    int pointLightBufferID     = Shader.PropertyToID("my_pointLightBuf");

    int spotLightBufferSizeID = Shader.PropertyToID("my_spotLightSize");
    int spotLightBufferID     = Shader.PropertyToID("my_spotLightBuf");

    Vector4[] _dirLightBuffer = new Vector4[maxLightSourcePerType * 2];
    Vector4[] _pntLightBuffer = new Vector4[maxLightSourcePerType * 2];
    Vector4[] _sptLightBuffer = new Vector4[maxLightSourcePerType * 4];

    static List<LightSource> lights = new List<LightSource>();
}


using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public abstract class MyBaseMonoRenderPass : MonoBehaviour
{
    public RenderPassEvent passEvent;

    public virtual void OnEnable() {
        MyRenderPassManager.instance.Register(this);
    }

    public virtual void OnDisable() {
        MyRenderPassManager.instance.Unregister(this);
    }

    public abstract void OnExecute(ScriptableRenderContext context, ref RenderingData renderingData);
}

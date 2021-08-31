using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MyPostProcessRenderFeature : ScriptableRendererFeature
{
    public override void Create() { }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        var manager = MyRenderPassManager.instance;
        if (manager == null) return;

        MyRenderPassManager.instance.AddRenderPasses(renderer, ref renderingData);
    }
}

public class MyScriptableRenderPass : ScriptableRenderPass
{
    MyBaseMonoRenderPass m_pass;

    public MyScriptableRenderPass(MyBaseMonoRenderPass pass_) {
        m_pass = pass_;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor) {
        m_pass?.OnConfigure(cmd, cameraTextureDescriptor);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
        m_pass?.OnExecute(context, ref renderingData);
    }

    public override void FrameCleanup(CommandBuffer cmd) {
        m_pass?.OnFrameCleanUp(cmd);
    }

}

public class MyRenderPassManager
{
    public static MyRenderPassManager instance {
        get {
            if (m_instance == null) {
                m_instance = new MyRenderPassManager();
            }
            return m_instance;
        }
    }
    static MyRenderPassManager m_instance;

    public void Register(MyBaseMonoRenderPass pass) {
        passesDict.Add(pass, new MyScriptableRenderPass(pass));
    }

    public void Unregister(MyBaseMonoRenderPass pass) {
        if (passesDict.ContainsKey(pass)) {
            passesDict.Remove(pass);
        }
    }

    public void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        foreach(var p in passesDict) {
            p.Value.renderPassEvent = p.Key.passEvent;
            renderer.EnqueuePass(p.Value);
        }
    }

    public Dictionary<MyBaseMonoRenderPass, MyScriptableRenderPass> passesDict = new Dictionary<MyBaseMonoRenderPass, MyScriptableRenderPass>();
}


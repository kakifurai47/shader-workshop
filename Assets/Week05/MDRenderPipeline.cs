using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

public class MDRenderPipeline : RenderPipeline
{
    CameraRenderer renderer = new CameraRenderer();

    protected override void Render(ScriptableRenderContext context, Camera[] cameras) {
        foreach(var cam in cameras) {
            renderer.Render(context, cam);
        }
    }
}

public class CameraRenderer
{
    ScriptableRenderContext context;
    Camera camera;

    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer { name = bufferName };

    static ShaderTagId defLitShadTagId   = new ShaderTagId("DeferredLit");
    static ShaderTagId defUnlitShadTagId = new ShaderTagId("DeferredUnlit");

    RenderTargetIdentifier[] identifiers;

    int baseColorRTID  = Shader.PropertyToID("_BaseColorRT");
    int positionWSRTID = Shader.PropertyToID("_PositionWSRT");
    int normalWSRTID   = Shader.PropertyToID("_NoramlWSRT");

    CullingResults cullingResults;

    static Mesh fullScreenTriangle;
    static Material deferredShadingMat;

    public CameraRenderer() {
        identifiers = new RenderTargetIdentifier[3];
        identifiers[0] = baseColorRTID;
        identifiers[1] = positionWSRTID;
        identifiers[2] = normalWSRTID;

        fullScreenTriangle = new Mesh() {
            name = "MyPostProcessSimple",
            vertices = new Vector3[] {
                    new Vector3(-1, -1, 0),
                    new Vector3( 3, -1, 0),
                    new Vector3(-1,  3, 0),
                },
            triangles = new int[] { 0, 1, 2 }
        };
        fullScreenTriangle.UploadMeshData(true);

        deferredShadingMat = new Material(Shader.Find("Week05/MyDeferredRenderShad"));
    }


    public void Render(ScriptableRenderContext context, Camera camera) {
        this.context = context;
        this.camera = camera;

        if (!Cull()) return;

        Setup();
        WriteToGBuffer();
        OnDeferredShading();
        DrawUnlit();
        DrawTransparent();
        Sumbit();
    }

    void Setup() {
        buffer.ClearRenderTarget(true, true, Color.clear);
        context.SetupCameraProperties(camera);
        buffer.BeginSample(bufferName);
    }

    void WriteToGBuffer() {
        var descriptor = new RenderTextureDescriptor() {
            width = camera.pixelWidth,
            height = camera.pixelHeight,
            dimension = TextureDimension.Tex2D,
            msaaSamples = 1,
        };

        descriptor.graphicsFormat = GraphicsFormat.R32G32B32A32_SFloat;
        buffer.GetTemporaryRT(baseColorRTID,  descriptor, FilterMode.Bilinear);
        buffer.GetTemporaryRT(positionWSRTID, descriptor, FilterMode.Bilinear);
        descriptor.graphicsFormat = GraphicsFormat.R16G16B16A16_SNorm;
        buffer.GetTemporaryRT(normalWSRTID,   descriptor, FilterMode.Bilinear);

        buffer.SetRenderTarget(identifiers, BuiltinRenderTextureType.CameraTarget);
        buffer.ClearRenderTarget(true, true, Color.clear);

        var sortingSettings = new SortingSettings(camera) {
            criteria = SortingCriteria.CommonOpaque,
        };
        var drawingSettings = new DrawingSettings(defLitShadTagId, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

        ExecuteBuffer();
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }

    void OnDeferredShading() {

        buffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);

        buffer.SetGlobalTexture(baseColorRTID,  baseColorRTID);
        buffer.SetGlobalTexture(positionWSRTID, positionWSRTID);
        buffer.SetGlobalTexture(normalWSRTID,   normalWSRTID);
        
        ExecuteBuffer();
        buffer.DrawMesh(fullScreenTriangle, Matrix4x4.identity, deferredShadingMat);

        buffer.ReleaseTemporaryRT(baseColorRTID);
        buffer.ReleaseTemporaryRT(positionWSRTID);
        buffer.ReleaseTemporaryRT(normalWSRTID);
    }

    void DrawUnlit() {
        var sortingSettings = new SortingSettings(camera) {
            criteria = SortingCriteria.CommonOpaque,
        };
        var drawingSettings = new DrawingSettings(defUnlitShadTagId, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        ExecuteBuffer();
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox(camera);
    }

    void DrawTransparent() {
        var sortingSettings = new SortingSettings(camera) {
            criteria = SortingCriteria.CommonTransparent,
        };
        var drawingSettings = new DrawingSettings(defUnlitShadTagId, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.transparent);
        ExecuteBuffer();
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }

    void Sumbit() {
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();
    }

    void ExecuteBuffer() {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    bool Cull() {
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p)) {
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }
}
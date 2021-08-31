using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class MyPostProcessSimple : MyBaseMonoRenderPass
{
    public Material postProcessMaterial;

    static Mesh fullScreenTriangle;

    public RenderTextureDescriptor d;

    public override void OnConfigure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor) {; }

    public override void OnExecute(ScriptableRenderContext context, ref RenderingData renderingData) {
        if (!postProcessMaterial) return;

        if (!fullScreenTriangle) {
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
        }

        CommandBuffer cmd = CommandBufferPool.Get(GetType().Name);
        cmd.Clear();
        cmd.DrawMesh(fullScreenTriangle, Matrix4x4.identity, postProcessMaterial);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);

        d = renderingData.cameraData.cameraTargetDescriptor;
    }

    public override void OnFrameCleanUp(CommandBuffer cmd) {; }
}

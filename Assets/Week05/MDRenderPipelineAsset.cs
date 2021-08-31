using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Week05/My Deferred Render Pipeline")]
public class MDRenderPipelineAsset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline() {
        return new MDRenderPipeline();
    }
}


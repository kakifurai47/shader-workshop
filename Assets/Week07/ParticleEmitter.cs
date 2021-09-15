using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;
using System.Runtime.InteropServices;
using Unity.Collections.LowLevel.Unsafe;
using UnityEngine.Rendering;

//WARNING: Should not be capturing when there is a hotcontrol
//         UnityEngine.GUIUtility:ProcessEvent(int, intptr, bool &)
public class ParticleEmitter : MonoBehaviour
{
    //public ParticleParameters paramters = ParticleParameters.Default();
    public Mesh               sampleMesh;
    public Material           material;
    public ComputeShader      solver;

    #region Start Paramters
    [Header("Paramters")]//should be static most of the time, will not resize buffer rn
    public int     particleCapacity = 1000;
    public float   activeCount;
    public float   lifeSpan;
    public float   deltaTime;

    public Vector3 forceField;
    public float   gravity;

    public Vector3 initVelocity;    
    int idxCntPerParticle;
    #endregion

    void OnEnable() {
        m_layout = new VertexAttributeDescriptor[] {
            new VertexAttributeDescriptor(VertexAttribute.Position,  VertexAttributeFormat.Float32, 3),
            new VertexAttributeDescriptor(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2),
        };

        m_instanceMeshBuffer = new ParticleMeshBuffer();
        m_combineMeshBuffer  = new ParticleMeshBuffer();
        m_stateBuffer        = new ParticleMeshBuffer();

        ResetMeshBuffer();
        BindSolverBuffer(0, ParticleMeshBuffer.Type.instance);
        BindSolverBuffer(0, ParticleMeshBuffer.Type.combine);
    }

    void Update() {
        Application.targetFrameRate = 60;
        if (!solver)
            return;

        //if (Mesh.changed) {
        //    SetMeshBuffer();
        //} 

        SetParams();
        
        solver.Dispatch(0, 1, 1, 1);
        BindMaterialBuffer();

        var bound = new Bounds(transform.position, Vector3.one * 1000);    
        Graphics.DrawProcedural(material, bound, MeshTopology.Triangles, m_combineMeshBuffer.IndexCount());
    }

    void ResetMeshBuffer() {//on mesh changed i.e. maximum Capacity, mesh shape, etc.
        m_instanceMeshBuffer.ResetAsInstanceBuffer(sampleMesh, m_layout);
        m_combineMeshBuffer.ResetAsCombineBuffer(sampleMesh, m_layout, particleCapacity);
        m_stateBuffer.ResetAsStateBuffer(statesBufferSize, particleCapacity);
    }

    void BindMaterialBuffer() {//on combine buffer changed
        material.SetBuffer(ShaderIds.combineVtx, m_combineMeshBuffer.VtxBuf());
        material.SetBuffer(ShaderIds.combineIdx, m_combineMeshBuffer.IdxBuf());            
    }

    void BindSolverBuffer(int kernel, ParticleMeshBuffer.Type type) {
        switch (type) {
            case ParticleMeshBuffer.Type.combine: {
                solver.SetBuffer(kernel, ShaderIds.combineVtx, m_combineMeshBuffer.VtxBuf());
                solver.SetBuffer(kernel, ShaderIds.combineIdx, m_combineMeshBuffer.IdxBuf());
            } break;
            case ParticleMeshBuffer.Type.instance: {
                solver.SetBuffer(kernel, ShaderIds.instanceVtx, m_instanceMeshBuffer.VtxBuf());
                solver.SetBuffer(kernel, ShaderIds.instanceIdx, m_instanceMeshBuffer.IdxBuf());
            }break;
        }
    }

    public void SetParams() {
        if (m_paramBuffer == null || m_paramBuffer.Length != paramsBufferSize) {
            m_paramBuffer = new Vector4[paramsBufferSize];
        }
        //const int pad0 = 0;

        m_paramBuffer[0] = new Vector4 {
            x = particleCapacity,
            y = activeCount,
            z = lifeSpan,
            w = Time.deltaTime,
        };
        m_paramBuffer[1] = new Vector4 {
            x = forceField.x,
            y = forceField.y,
            z = forceField.z,
            w = gravity,
        };

        m_paramBuffer[2] = new Vector4 {
            x = initVelocity.x,
            y = initVelocity.y,
            z = initVelocity.z,
            w = sampleMesh.GetIndexCount(0),
        };

        solver.SetVectorArray(ShaderIds.param, m_paramBuffer);
    }

    void OnDisable() {
        m_instanceMeshBuffer?.ReleaseBuffer();
        m_combineMeshBuffer?.ReleaseBuffer();
        m_stateBuffer?.ReleaseBuffer();
    }

    const int paramsBufferSize = 3;
    const int statesBufferSize = 1;
    Vector4[] m_paramBuffer;
    VertexAttributeDescriptor[] m_layout;

    ParticleMeshBuffer m_instanceMeshBuffer;
    ParticleMeshBuffer m_combineMeshBuffer;
    ParticleMeshBuffer m_stateBuffer;

    struct ShaderIds {
        public static readonly int param       = Shader.PropertyToID("ParticleEffect_Param");
        public static readonly int state       = Shader.PropertyToID("ParticleEffect_States");
        public static readonly int instanceVtx = Shader.PropertyToID("ParticleEffect_InstanceVtxs");
        public static readonly int instanceIdx = Shader.PropertyToID("ParticleEffect_InstanceIdxs");
        public static readonly int combineVtx  = Shader.PropertyToID("ParticleEffect_CombineVtxs");
        public static readonly int combineIdx  = Shader.PropertyToID("ParticleEffect_CombineIdxs");
    }
}

//==============================================================================================

public class ParticleMeshBuffer
{
    public enum Type { instance = 0, combine = 1, }

    public void ResetAsInstanceBuffer(Mesh mesh, VertexAttributeDescriptor[] layout) {
        var extractor = new VertexBufferExtractor();
        var vtxBuf = extractor.Execute(mesh, layout);
        var idxBuf = mesh.triangles;

        var vtxCnt = (int)mesh.vertexCount;      var vtxSize_32t = extractor.vtxSize;
        var idxCnt = (int)mesh.GetIndexCount(0); var idxSize_32t = 1;

        ReleaseBuffer();
        m_vtxBuffer = new ComputeBuffer(vtxCnt, vtxSize_32t * sizeof(float)); m_vtxBuffer.SetData(vtxBuf);
        m_idxBuffer = new ComputeBuffer(idxCnt, idxSize_32t * sizeof(int));   m_idxBuffer.SetData(idxBuf);
        extractor.Clear();
    }

    public void ResetAsCombineBuffer(Mesh mesh, VertexAttributeDescriptor[] layout, int particleCap) {        
        var extractor = new VertexBufferExtractor();
        var vtxCnt = (int)mesh.vertexCount;      var vtxSize_32t = extractor.GetVertexSize(layout);
        var idxCnt = (int)mesh.GetIndexCount(0); var idxSize_32t = 1;

        ReleaseBuffer();
        m_vtxBuffer = new ComputeBuffer(particleCap * vtxCnt, vtxSize_32t * sizeof(float));
        m_idxBuffer = new ComputeBuffer(particleCap * idxCnt, idxSize_32t * sizeof(float));
        extractor.Clear();
    }

    public void ResetAsStateBuffer(int stateAttSize, int particleCap) {
        ReleaseBuffer();
        m_parBuffer = new ComputeBuffer(particleCap, stateAttSize * sizeof(float));
    }


    public int IndexCount() => m_idxBuffer.count;
    public ComputeBuffer VtxBuf() => m_vtxBuffer;
    public ComputeBuffer IdxBuf() => m_idxBuffer;
    public ComputeBuffer StaBuf() => m_parBuffer;

    public void ReleaseBuffer() {
        m_vtxBuffer?.Release();
        m_idxBuffer?.Release();
        m_parBuffer?.Release();

        m_vtxBuffer = null;
        m_idxBuffer = null;
        m_parBuffer = null;
    }

    ComputeBuffer m_vtxBuffer;
    ComputeBuffer m_idxBuffer;
    ComputeBuffer m_parBuffer;
}

//============================================================


public struct VertexBufferExtractor //LIMIT:
                                    //=> no compression, use what mesh.atts returned, i.e. norm's dim = 3 rn
                                    //=> fmt, is limit to float32, i.e. TODO pack 2float16 => float32
                                    //=> exist implicit cast, might loss precision? , i.e. (float)Unorm
                                    //=> error handle, e.x. check valid tgtLayout
{
    public int vtxSize;
    float[] m_buf;//change to list to avoid reallocation

    public float[] Execute(Mesh mesh, VertexAttributeDescriptor[] tgtLayout) {
        Clear();

        int offset  = 0;
        vtxSize = GetVertexSize(tgtLayout);
        m_buf = new float[mesh.vertexCount * vtxSize];
        foreach (var descriptor in tgtLayout) {
            var att     = descriptor.attribute;
            var attSize = GetByteSize(descriptor.format) * descriptor.dimension / sizeof(float);//in term of float
        
            switch (att) {
                case VertexAttribute.Position:  { var src = mesh.vertices; Serialize(src, m_buf, offset, vtxSize); offset += attSize; }break;
                case VertexAttribute.Normal:    { var src = mesh.normals;  Serialize(src, m_buf, offset, vtxSize); offset += attSize; }break;
                case VertexAttribute.Tangent:   { var src = mesh.tangents; Serialize(src, m_buf, offset, vtxSize); offset += attSize; }break;
                case VertexAttribute.Color:     { var src = mesh.colors32; Serialize(src, m_buf, offset, vtxSize); offset += attSize; }break;
                case VertexAttribute.TexCoord0: { var src = mesh.uv;       Serialize(src, m_buf, offset, vtxSize); offset += attSize; }break;
            }
        }
        return m_buf;
    }

    public int GetVertexSize(VertexAttributeDescriptor[] layout) {
        var size = 0;
        foreach (var descriptor in layout) {
            var fmt = descriptor.format;
            size += GetByteSize(descriptor.format) * descriptor.dimension / sizeof(float);
        }
        return size;
    }

    public void Clear() {
        if(m_buf != null) {
            System.Array.Clear(m_buf, 0, m_buf.Length);
            m_buf = null;
        }            
        vtxSize = 0;
    }

    void Serialize(float[] src, float[] dst, int offset, int vtxSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2;
            index += vtxSize;
        }
    }

    void Serialize(Vector2[] src, float[] dst, int offset, int vtxSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.x;
            dst[index + 1] = v2.y;
            index += vtxSize;
        }
    }

    void Serialize(Vector3[] src, float[] dst, int offset, int vtxSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.x;
            dst[index + 1] = v2.y;
            dst[index + 2] = v2.z;
            index += vtxSize;
        }
    }

    void Serialize(Vector4[] src, float[] dst, int offset, int vtxSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.x;
            dst[index + 1] = v2.y;
            dst[index + 2] = v2.z;
            dst[index + 3] = v2.w;
            index += vtxSize;
        }
    }

    void Serialize(Color32[] src, float[] dst, int offset, int vtxSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.r;
            dst[index + 1] = v2.g;
            dst[index + 2] = v2.b;
            dst[index + 3] = v2.a;
            index += vtxSize;
        }
    }
    int GetByteSize(VertexAttributeFormat fmt) {
        switch (fmt) {
            case VertexAttributeFormat.Float32: return 4;
            case VertexAttributeFormat.Float16: return 2;
            case VertexAttributeFormat.UNorm8:  return 1;
            case VertexAttributeFormat.SNorm8:  return 1;
            case VertexAttributeFormat.UNorm16: return 2;
            case VertexAttributeFormat.SNorm16: return 2;
            case VertexAttributeFormat.UInt8:   return 1;
            case VertexAttributeFormat.SInt8:   return 1;
            case VertexAttributeFormat.UInt16:  return 2;
            case VertexAttributeFormat.SInt16:  return 2;
            case VertexAttributeFormat.UInt32:  return 4;
            case VertexAttributeFormat.SInt32:  return 4;
        }
        return -1;//Handle this
    }
}
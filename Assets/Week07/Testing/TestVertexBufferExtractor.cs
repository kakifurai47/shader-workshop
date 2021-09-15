using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;



[ExecuteInEditMode]
public class TestVertexBufferExtractor : MonoBehaviour
{
    public Mesh testMesh;

    VertexBufferExtractor extractor;


    void OnEnable() {
        extractor = new VertexBufferExtractor();
        //Test0();
        //Test1();
        Test2();
    }




    void InitWith(float[] tgt, int d) { for (int i = 0; i < tgt.Length; i++) tgt[i] = -1; }
    void Test0() {

        var vtxCnt = 3;
        var vtxSize = 3 + 1 + 4 + 4 + 2;
        var src0 = new Vector3[vtxCnt];
        var src1 = new float  [vtxCnt];
        var src2 = new Vector4[vtxCnt];
        var src3 = new Color32[vtxCnt];
        var src4 = new Vector2[vtxCnt];

        byte idx = 0;
        for(int i = 0; i < vtxCnt; i++) 
        {
            src0[i] = new Vector3(idx++, idx++, idx++); 
            src1[i] = idx++;
            src2[i] = new Vector4(idx++, idx++, idx++, idx++);
            src3[i] = new Color32(idx++, idx++, idx++, idx++);
            src4[i] = new Vector2(idx++, idx++);
        }

        var dst    = new float[vtxCnt * vtxSize];
        InitWith(dst, -1);
        var offset = 0;
        Serialize(src0, dst, offset, vtxSize); offset += 3;
        Serialize(src1, dst, offset, vtxSize); offset += 1;
        Serialize(src2, dst, offset, vtxSize); offset += 4;
        Serialize(src3, dst, offset, vtxSize); offset += 4;
        Serialize(src4, dst, offset, vtxSize); offset += 2;

        for(int i = 0; i < dst.Length; i++) {
            Debug.Assert(i == (int)dst[i]);
        }
    }
    void Test1() { //test individually
        var layout = new VertexAttributeDescriptor[] {
            //new VertexAttributeDescriptor(VertexAttribute.Position, VertexAttributeFormat.Float32, 3),
            //new VertexAttributeDescriptor(VertexAttribute.Normal,   VertexAttributeFormat.Float32, 3),
            //new VertexAttributeDescriptor(VertexAttribute.Tangent,  VertexAttributeFormat.Float32,  4),
            new VertexAttributeDescriptor(VertexAttribute.TexCoord0,  VertexAttributeFormat.Float32,  2),
        };

        var dst = extractor.Execute(testMesh, layout);

        //var buf = testMesh.vertices; int attSize = 3;
        //var buf = testMesh.normals;  int attSize = 3;
        //var buf = testMesh.tangents; int attSize = 4;
        var buf = testMesh.uv;       int attSize = 2;

        for (int i = 0; i < buf.Length; i++) {
            var val = buf[i];
            //Debug.Log(dst[i * attSize + 0] + ", " +  val.x);
            //Debug.Log(dst[i * attSize + 1] + ", " +  val.y);
            //Debug.Log(dst[i * attSize + 2] + ", " +  val.z);
            //Debug.Log(dst[i * attSize + 3] + ", " +  val.w);

            Debug.Assert(nearlyEqual(dst[i * attSize + 0], val.x, Mathf.Epsilon));
            Debug.Assert(nearlyEqual(dst[i * attSize + 1], val.y, Mathf.Epsilon));
            //Debug.Assert(nearlyEqual(dst[i * attSize + 2], val.z, Mathf.Epsilon));
            //Debug.Assert(nearlyEqual(dst[i * attSize + 3], val.w, Mathf.Epsilon));
        }
    }

    void Test2() {
        var layout = new VertexAttributeDescriptor[] {
            new VertexAttributeDescriptor(VertexAttribute.Position,  VertexAttributeFormat.Float32, 3),
            new VertexAttributeDescriptor(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2),
            new VertexAttributeDescriptor(VertexAttribute.Normal,    VertexAttributeFormat.Float32, 3),
            new VertexAttributeDescriptor(VertexAttribute.Tangent,   VertexAttributeFormat.Float32, 4),
            
        };

        var dst = extractor.Execute(testMesh, layout);

        var src0 = testMesh.vertices;
        var src1 = testMesh.uv;
        var src2 = testMesh.normals;
        var src3 = testMesh.tangents;

        var vtxSize = 3 + 3 + 4 + 2;

        var idx = 0;
        for(int i = 0; i < vtxSize; i++) {
            Debug.Assert(src0[i + 0] == new Vector3(dst[idx++], dst[idx++], dst[idx++]));
            Debug.Assert(src1[i + 0] == new Vector2(dst[idx++], dst[idx++]));
            Debug.Assert(src2[i + 0] == new Vector3(dst[idx++], dst[idx++], dst[idx++]));
            Debug.Assert(src3[i + 0] == new Vector4(dst[idx++], dst[idx++], dst[idx++], dst[idx++]));
        }
    }


    void Serialize(float[] src, float[] dst, int offset, int attSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2;
            index += attSize;
        }
    }

    void Serialize(Vector2[] src, float[] dst, int offset, int attSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.x;
            dst[index + 1] = v2.y;
            index += attSize;
        }
    }

    void Serialize(Vector3[] src, float[] dst, int offset, int attSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.x;
            dst[index + 1] = v2.y;
            dst[index + 2] = v2.z;
            index += attSize;
        }
    }

    void Serialize(Vector4[] src, float[] dst, int offset, int attSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.x;
            dst[index + 1] = v2.y;
            dst[index + 2] = v2.z;
            dst[index + 3] = v2.w;
            index += attSize;
        }
    }

    void Serialize(Color32[] src, float[] dst, int offset, int attSize) {
        var index = offset;
        for (int i = 0; i < src.Length; i++) {
            var v2 = src[i];
            dst[index + 0] = v2.r;
            dst[index + 1] = v2.g;
            dst[index + 2] = v2.b;
            dst[index + 3] = v2.a;
            index += attSize;
        }
    }

    public static bool nearlyEqual(float a, float b, float epsilon) {
        float absA = Mathf.Abs(a);
        float absB = Mathf.Abs(b);
        float diff = Mathf.Abs(a - b);

        if (a == b) { // shortcut, handles infinities
            return true;
        }
        else if (a == 0 || b == 0 || absA + absB < float.MinValue) {
            // a or b is zero or both are extremely close to it
            // relative error is less meaningful here
            return diff < (epsilon * float.MinValue);
        }
        else { // use relative error
            return diff / (absA + absB) < epsilon;
        }
    }

}

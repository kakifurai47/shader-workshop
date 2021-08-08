using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class DissolveVertexSolver : MonoBehaviour
{
    Mesh _mesh;

    private void Awake() {
        Application.targetFrameRate = 60;
    }

    void Start() => RecalculateMesh();

    void RecalculateMesh() {

        if (!_mesh) {
            var filter = GetComponent<MeshFilter>();
            if (!filter) return;
            _mesh = filter.mesh;
        }

        var idxs  = _mesh.GetIndices(0);
        var vtxs  = _mesh.vertices;
        var uvs   = _mesh.uv;

        var vertCount = idxs.Length;
        var newIdxs   = new int[vertCount];
        var newVtxs   = new Vector3[vertCount];
        var newUVs    = new Vector4[vertCount];
        var newNorms  = new Vector3[vertCount];
        var vanishPts = new Vector3[vertCount];

        for(int i = 0; i < vertCount; i++) {            
            var idx    = idxs[i];
            var newVtx = vtxs[idx];
            var newUV  = uvs [idx];

            newIdxs[i] = i;
            newVtxs[i] = newVtx;
            newUVs [i] = newUV;

            if (i % 3 == 2) {
                var p0 = newVtxs[i - 2];
                var p1 = newVtxs[i - 1];                

                var v0 = newVtx - p1;
                var v1 = newVtx - p0;
                var norm = Vector3.Normalize(Vector3.Cross(v1, v0));
                newNorms[i - 2] = norm;                
                newNorms[i - 1] = norm;
                newNorms[i - 0] = norm;

                var vanishPt = (p0 + p1 + newVtx) / 3.0f;
                vanishPts[i - 2] = vanishPt;
                vanishPts[i - 1] = vanishPt;                
                vanishPts[i - 0] = vanishPt;

                var xPerTriUV = (newUVs[i - 2].x + newUVs[i - 1].x + newUV.x) / 3;
                var yperTriUV = (newUVs[i - 2].y + newUVs[i - 1].y + newUV.y) / 3;
                var perTriUV = new Vector4(0, 0, xPerTriUV, yperTriUV);
                newUVs[i - 2] += perTriUV;
                newUVs[i - 1] += perTriUV;
                newUVs[i - 0] += perTriUV;
            }
        }

        _mesh.SetVertices(newVtxs, 0, vertCount);
        _mesh.SetIndices(newIdxs, MeshTopology.Triangles, 0);
        _mesh.SetNormals(newNorms);
        _mesh.SetUVs(0, newUVs);        
        _mesh.SetUVs(1, vanishPts);
    }
}

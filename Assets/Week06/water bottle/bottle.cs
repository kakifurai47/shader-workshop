using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class MyQuatUtil {

    public static Quaternion MultiplyByFloat(this Quaternion q_, float f) {
        var q = Quaternion.identity;
        q.x = q_.x * f;
        q.y = q_.y * f;
        q.z = q_.z * f;
        q.w = q_.w * f;

        return q;
    }

    public static Quaternion Diff(Quaternion lhs, Quaternion rhs) {
        var q = Quaternion.identity;
        q.x = lhs.x - rhs.x;
        q.y = lhs.y - rhs.y;
        q.z = lhs.z - rhs.z;
        q.w = lhs.w - rhs.w;

        return q;
    }

    public static Quaternion Add(Quaternion lhs, Quaternion rhs) {
        var q = Quaternion.identity;
        q.x = lhs.x + rhs.x;
        q.y = lhs.y + rhs.y;
        q.z = lhs.z + rhs.z;
        q.w = lhs.w + rhs.w;

        return q;
    }
}

[ExecuteInEditMode]
public class bottle : MonoBehaviour
{
    public Transform liquid;

    public float height = 0;
    public float k_mass = 0.001f;
    public float k_damping = 0.1f;
    public float k_springConstant = 0.5f;

    Material liquidMaterial;    
    static readonly int planeID = Shader.PropertyToID("_Plane");

    Vector3 m_lastPos = Vector3.zero;

    Quaternion m_botLastRot = Quaternion.identity;
    Quaternion m_liqLastRot = Quaternion.identity;
    Quaternion m_velocity   = Quaternion.identity;
    Quaternion m_target     = Quaternion.identity;

    private void OnEnable() {
        ResetAtt();
    }

    void Update() {

        if(Quaternion.Dot(m_botLastRot, transform.rotation) < 1 - Mathf.Epsilon) {
            var deltaRot = transform.rotation * Quaternion.Inverse(m_botLastRot);
            m_liqLastRot = deltaRot * m_liqLastRot;
            m_botLastRot = transform.rotation;
        }

        if (Vector3.SqrMagnitude(transform.position - m_lastPos) > Mathf.Epsilon) {
            OnTranslate();
        }

        if (Quaternion.Dot(m_liqLastRot, m_target) < 1 - Mathf.Epsilon) {
            OnRotate();
        }

        SetMaterialProperties();

        if (Input.GetKeyDown("m")) {
            ResetAtt();
        }
    }

    void OnTranslate() {
        var forward = m_liqLastRot * Vector3.forward;
        var upward = m_liqLastRot * Vector3.up;
        upward += m_lastPos - transform.position;

        m_liqLastRot = Quaternion.LookRotation(forward, upward);
        m_lastPos = transform.position;
    }

    void OnRotate() {
        var deltaTime = Time.deltaTime;

        var deltaRot = m_target * Quaternion.Inverse(m_liqLastRot);
        var acc0 = deltaRot.MultiplyByFloat(k_springConstant);
        var acc1 = m_velocity.MultiplyByFloat(k_damping);
        var restoreF = MyQuatUtil.Diff(acc0, acc1).MultiplyByFloat(1 / k_mass);

        m_velocity   = MyQuatUtil.Add(m_velocity,   restoreF.MultiplyByFloat(deltaTime));
        m_liqLastRot = MyQuatUtil.Add(m_liqLastRot, m_velocity.MultiplyByFloat(deltaTime));

        m_liqLastRot = Quaternion.Normalize(m_liqLastRot);
    }


    void SetMaterialProperties() {
        var norm = m_liqLastRot * Vector3.up;
        var pos = transform.position;
        pos.y = height;
        var plane = new Vector4(norm.x, norm.y, norm.z, -Vector3.Dot(norm, pos));

        if (!liquidMaterial) {
            liquidMaterial = liquid.GetComponent<Renderer>().sharedMaterial;
        }

        liquidMaterial.SetVector(planeID, plane);
    }

    public void ResetAtt() {
        transform.position = Vector3.zero;
        transform.rotation = Quaternion.identity;
        m_botLastRot = transform.rotation;
        m_liqLastRot = transform.rotation;
    }
}

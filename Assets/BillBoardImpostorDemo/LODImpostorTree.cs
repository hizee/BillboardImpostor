using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LODImpostorTree : MonoBehaviour
{
    public GameObject LOD0;
    public GameObject LOD1;


    // Update is called once per frame
    void Update()
    {
        float distance = (transform.position - Camera.main.transform.position).magnitude;
        if (distance > 20)
        {
            LOD1.SetActive(true);
            LOD0.SetActive(false);
        }
        else {
            LOD1.SetActive(false);
            LOD0.SetActive(true);
        }
    }
}

using UnityEngine;
[ExecuteInEditMode]
public class MainLightData : MonoBehaviour
{
	public Light mainLight;

	void OnEnable()
	{
		mainLight = GetComponent<Light>();
	}

	
	void Update ()
	{
		//Shader.SetGlobalVector("_LightDirection", -transform.forward);
		//Shader.SetGlobalColor("_LightColor", mainLight.color);
        Shader.SetGlobalFloat("_LightIntensity", mainLight.intensity); // can't figure out how to get light intensity in shader graph
	}
}
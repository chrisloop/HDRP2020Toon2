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
        Shader.SetGlobalFloat("_LightIntensity", mainLight.intensity); // fix later to get intensity without a script
	}
}
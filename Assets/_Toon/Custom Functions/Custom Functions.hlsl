#ifndef SHADERGRAPH_PREVIEW
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.cs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowManager.cs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowSampling.hlsl"    
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"

    void GetDepthNormal_float(float2 ScreenPosition, out float Depth, out float3 Normal)
    {
        Depth = SampleCameraDepth(ScreenPosition);
        NormalData normalData;
        DecodeFromNormalBuffer(_ScreenSize.xy * ScreenPosition, normalData);
        Normal = normalData.normalWS;     
    }
#endif

void GetAO_float(float2 uv, out float AO)
{
    AO = 1;

    #ifndef SHADERGRAPH_PREVIEW

       AO = SAMPLE_TEXTURE2D_X(_AmbientOcclusionTexture, s_linear_clamp_sampler, uv * _RTHandleScale.xy).r;

    #endif
}

void GetShadow_float(float2 uv, out float3 Shadow)
{
    Shadow = 1;

    #ifndef SHADERGRAPH_PREVIEW

       Shadow = SAMPLE_TEXTURE2D_X(_ScreenSpaceShadowsTexture, s_linear_clamp_sampler, uv * _RTHandleScale.xy);

    #endif
}

void ShadowEdges_float(float2 ScreenPosition, float EdgeRadius, float Multiplier, float ShadowBias, int Samples,
    out float ShadowEdges)
{
    ShadowEdges = 0;

    EdgeRadius = EdgeRadius * _ScreenParams.y / 1080; // screen size scaling

    if (Multiplier <= 0)
        return;

    #ifndef SHADERGRAPH_PREVIEW

        float Shadow = SAMPLE_TEXTURE2D_X(_ScreenSpaceShadowsTexture, s_linear_clamp_sampler, ScreenPosition * _RTHandleScale.xy);

        // Neighbour pixel positions
        static float2 samplingPositions[8] =
        {
            float2( 0,  1),
            float2(-1,  0),
            float2( 0, -1),
            float2( 1,  0),
            float2( 1,  1),
            float2(-1,  1),
            float2(-1, -1),
            float2( 1, -1),
        };

        float shadowDifference = 0;

        float shadowSample;
        //float3 normalSample;

        for (int i = 0; i < Samples; i++)
        {
            shadowSample = SAMPLE_TEXTURE2D_X(_ScreenSpaceShadowsTexture, s_linear_clamp_sampler, (ScreenPosition * _RTHandleScale.xy) + samplingPositions[i] * EdgeRadius * _ScreenSize.zw);
            shadowDifference = shadowDifference + Shadow - shadowSample.r;
        }

        // shadow sensitivity
        shadowDifference = shadowDifference * Multiplier;
        shadowDifference = pow(shadowDifference, ShadowBias); 
        ShadowEdges = shadowDifference;
    #endif
}

void GetSun_float(out float3 LightDirection, out float3 Color)
{
    LightDirection = float3(0.5, 0.5, 0);
    Color = 1;

    #ifndef SHADERGRAPH_PREVIEW
        if (_DirectionalLightCount > 0)
        {
            DirectionalLightData light = _DirectionalLightDatas[0];
            LightDirection = -light.forward.xyz;
            Color = light.color;
        }

    #endif
}

void Edges_float(float2 ScreenPosition, float EdgeRadius, float DepthMultiplier, float DepthBias, float NormalMultiplier, float NormalBias, int Samples,
    out float Depth, out float3 Normal, out float Edges)
{
    Normal = 1;
    Depth = 0;
    Edges = 1;

    EdgeRadius = EdgeRadius * _ScreenParams.y / 1080; // screen size scaling

    #ifndef SHADERGRAPH_PREVIEW

        #define MAX_SAMPLES 8

        // Neighbour pixel positions
        static float2 samplingPositions[MAX_SAMPLES] =
        {
            float2( 0,  1),
            float2(-1,  0),
            float2( 0, -1),
            float2( 1,  0),
            float2( 1,  1),
            float2(-1,  1),
            float2(-1, -1),
            float2( 1, -1),
        };

        float depthDifference = 0;
        float normalDifference = 0;


        // center position
        GetDepthNormal_float(ScreenPosition, Depth, Normal);

        float depthSample;
        float3 normalSample;

        for (int i = 0; i < Samples; i++)
        {

            GetDepthNormal_float(ScreenPosition + samplingPositions[i] * EdgeRadius * _ScreenSize.zw, depthSample, normalSample);
            depthDifference = depthDifference + Depth - depthSample;
            normalDifference = normalDifference + Normal - normalSample;
        }

        // depth sensitivity
        depthDifference = depthDifference * DepthMultiplier;
        depthDifference = saturate(depthDifference);
        depthDifference = pow(depthDifference, DepthBias);
        float EdgeDepth = depthDifference;    

        // normal sensitivity
        normalDifference = normalDifference * NormalMultiplier;
        normalDifference = saturate(normalDifference);
        normalDifference = pow(normalDifference, NormalBias);
        float EdgeNormal = normalDifference;    

        Edges = max(EdgeDepth, EdgeNormal); 

    #endif
}
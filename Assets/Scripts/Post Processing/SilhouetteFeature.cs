using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class SilhouetteFeature : ScriptableRendererFeature
{
    private SilhouetteRenderPass pass = new();

    public override void Create()
    {
        name = "Silhouette";
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var settings = VolumeManager.instance.stack.GetComponent<SilhouetteSettings>();

        if (settings != null && settings.IsActive())
        {
            renderer.EnqueuePass(pass);
        }
    }

    class SilhouetteRenderPass : ScriptableRenderPass
    {
        private Material material;

        public SilhouetteRenderPass()
        {
            profilingSampler = new ProfilingSampler("Silhouette Post Process");
            renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
            requiresIntermediateTexture = false;
        }

        private void FindMaterial()
        {
            if (material != null) return;
            
            var shader = Shader.Find("Basics/Silhouette");
            material = new Material(shader);
        }

        private class MainPassData
        {
            public Material material;
            public TextureHandle inputTexture;
        }

        private static void ExecuteMainPass(RasterCommandBuffer cmd, MainPassData data)
        {
            Blitter.BlitTexture(cmd, data.inputTexture, new Vector4(1, 1, 0, 0), data.material, 0);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            FindMaterial();
            ConfigureInput(ScriptableRenderPassInput.Depth);
            
            var resourceData = frameData.Get<UniversalResourceData>();
            
            var settings = VolumeManager.instance.stack.GetComponent<SilhouetteSettings>();
            material.SetColor("_NearColor", settings.nearColor.value);
            material.SetColor("_FarColor", settings.farColor.value);
            material.SetFloat("_DepthPower", settings.depthPower.value);
            
            using (var builder = renderGraph.AddRasterRenderPass<MainPassData>("Silhouette_MainPass", out var passData, profilingSampler))
            {
                passData.material = material;
                passData.inputTexture = resourceData.activeDepthTexture;

                builder.UseTexture(resourceData.activeDepthTexture, AccessFlags.Read);
                builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);
                
                builder.SetRenderFunc(static (MainPassData data, RasterGraphContext context) => 
                    ExecuteMainPass(context.cmd, data));
            }
        }
    }
}

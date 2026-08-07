using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class GreyscaleFeature : ScriptableRendererFeature
{
    private GreyscaleRenderPass pass = new();

    public override void Create()
    {
        name = "Greyscale";
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var settings = VolumeManager.instance.stack.GetComponent<GreyscaleSettings>();

        if (settings != null && settings.IsActive())
        {
            renderer.EnqueuePass(pass);
        }
    }

    class GreyscaleRenderPass : ScriptableRenderPass
    {
        private Material material;

        public GreyscaleRenderPass()
        {
            profilingSampler = new ProfilingSampler("Greyscale Post Process");
            renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
            requiresIntermediateTexture = true;
        }

        private void FindMaterial()
        {
            if (material != null) return;
            
            var shader = Shader.Find("Basics/Greyscale");
            material = new Material(shader);
        }

        private static RenderTextureDescriptor GetCopyPassDescriptor(RenderTextureDescriptor descriptor)
        {
            descriptor.msaaSamples = 1;
            descriptor.depthBufferBits = (int)DepthBits.None;
            return descriptor;
        }

        private class CopyPassData
        {
            public TextureHandle inputTexture;
        }

        private class MainPassData
        {
            public Material material;
            public TextureHandle inputTexture;
        }

        private static void ExecuteCopyPass(RasterCommandBuffer cmd, CopyPassData data)
        {
            Blitter.BlitTexture(cmd, data.inputTexture, new Vector4(1, 1, 0, 0), 0.0f, false);
        }

        private static void ExecuteMainPass(RasterCommandBuffer cmd, MainPassData data)
        {
            Blitter.BlitTexture(cmd, data.inputTexture, new Vector4(1, 1, 0, 0), data.material, 0);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            FindMaterial();
            
            var resourceData = frameData.Get<UniversalResourceData>();
            var cameraData = frameData.Get<UniversalCameraData>();
            
            var colorCopyDescriptor = GetCopyPassDescriptor(cameraData.cameraTargetDescriptor);
            var colorCopy = UniversalRenderer.CreateRenderGraphTexture(renderGraph, colorCopyDescriptor, 
                "_GreyscaleColorCopy", false);
            
            var settings = VolumeManager.instance.stack.GetComponent<GreyscaleSettings>();
            material.SetFloat("_Strength", settings.strength.value);
            
            using (var builder = renderGraph.AddRasterRenderPass<CopyPassData>("Greyscale_CopyColor", out var passData, profilingSampler))
            {
                passData.inputTexture = resourceData.activeColorTexture;

                builder.UseTexture(resourceData.activeColorTexture, AccessFlags.Read);
                builder.SetRenderAttachment(colorCopy, 0, AccessFlags.Write);
                
                builder.SetRenderFunc(static (CopyPassData data, RasterGraphContext context) => 
                    ExecuteCopyPass(context.cmd, data));
            }
            
            using (var builder = renderGraph.AddRasterRenderPass<MainPassData>("Greyscale_MainPass", out var passData, profilingSampler))
            {
                passData.material = material;
                passData.inputTexture = colorCopy;

                builder.UseTexture(colorCopy, AccessFlags.Read);
                builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);
                
                builder.SetRenderFunc(static (MainPassData data, RasterGraphContext context) => 
                    ExecuteMainPass(context.cmd, data));
            }
        }
    }
}

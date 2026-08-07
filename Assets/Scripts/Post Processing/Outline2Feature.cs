using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class Outline2Feature : ScriptableRendererFeature
{
    private Outline2RenderPass pass = new();

    public override void Create()
    {
        name = "Outline 2";
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var settings = VolumeManager.instance.stack.GetComponent<Outline2Settings>();

        if (settings != null && settings.IsActive())
        {
            renderer.EnqueuePass(pass);
        }
    }

    class Outline2RenderPass : ScriptableRenderPass
    {
        private Material material;

        public Outline2RenderPass()
        {
            profilingSampler = new ProfilingSampler("Outline 2 Post Process");
            renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
            requiresIntermediateTexture = true;
        }

        private void FindMaterial()
        {
            if (material != null) return;
            
            var shader = Shader.Find("Basics/Outline2");
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
            ConfigureInput(ScriptableRenderPassInput.Depth);
            ConfigureInput(ScriptableRenderPassInput.Normal);
            
            var resourceData = frameData.Get<UniversalResourceData>();
            var cameraData = frameData.Get<UniversalCameraData>();
            
            var colorCopyDescriptor = GetCopyPassDescriptor(cameraData.cameraTargetDescriptor);
            var colorCopy = UniversalRenderer.CreateRenderGraphTexture(renderGraph, colorCopyDescriptor, 
                "_Outline2ColorCopy", false);
            
            var settings = VolumeManager.instance.stack.GetComponent<Outline2Settings>();
            material.SetFloat("_Strength", settings.strength.value);
            material.SetColor("_OutlineColor", settings.outlineColor.value);
            material.SetFloat("_ColorThreshold",  settings.colorThreshold.value);
            material.SetFloat("_DepthThreshold",  settings.depthThreshold.value);
            material.SetFloat("_NormalThreshold",  settings.normalThreshold.value);
            
            using (var builder = renderGraph.AddRasterRenderPass<CopyPassData>("Outline2_CopyColor", out var passData, profilingSampler))
            {
                passData.inputTexture = resourceData.activeColorTexture;

                builder.UseTexture(resourceData.activeColorTexture, AccessFlags.Read);
                builder.SetRenderAttachment(colorCopy, 0, AccessFlags.Write);
                
                builder.SetRenderFunc(static (CopyPassData data, RasterGraphContext context) => 
                    ExecuteCopyPass(context.cmd, data));
            }
            
            using (var builder = renderGraph.AddRasterRenderPass<MainPassData>("Outline2_MainPass", out var passData, profilingSampler))
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

{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap to initialize Flutter Web with the HTML renderer
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      // Force the HTML renderer for better compatibility with google_maps_flutter_web
      renderer: "html"
    });
    await appRunner.runApp();
  }
});

# Full layout image generation

- Open in Klayout
- Load Matt Venn's `caravel.lyp` layer properties file with `File -> Load Layer Properties` from [here](https://github.com/mattvenn/klayout_properties).
- Generate the image by running this in macro development: `RBA::Application.instance.main_window.current_view.save_image("/tmp/filename.png",10000,10000)`.

layout\_full includes layout\_design\_top with the user\_project\_wrapper power rings around it.

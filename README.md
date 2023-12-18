# CaveEditor
3D Cave editor using [Godot](https://godotengine.org/) and [godot_voxel module](https://github.com/Zylann/godot_voxel).

## Features
- Edit terrain using tools:
  - Sphere
  - Cube
  - Blend ball.
- Terrain changes are automatically saved in a file.

## Project binary releases
For Windows:
- https://github.com/Piratux/CaveEditor/releases/tag/Windows <br />

## Running the project from editor
- Download files from this repository.
- Download compiled godot editor with module.
  - On Windows, download editor from here https://github.com/Zylann/godot_voxel/actions/runs/4724932919 named 
`godot.windows.editor.x86_64.exe`.
  - On Linux, download editor from here https://github.com/Zylann/godot_voxel/actions/runs/4724932921 named `godot.linuxbsd.editor.x86_64`.
  - On other platforms or architectures, you will need to compile godot with the module yourself (see https://voxel-tools.readthedocs.io/en/latest/getting_the_module/).
- Run the godot editor.
- When Godot's project manager opens up, import the project (this only needs to be done once).
  - Click `Import`
  - Click `Browse`
  - Locate `CaveEditor/project.godot`
  - Click `Open`
  - Click `Import & Edit`
- When Godot's editor loads up, press F5 or click `Run project` button on the top right to run the project.

## Building from source
build godot editor:
scons platform=windows

build godot template release:
scons platform=windows target=template_release

# CaveEditor
3D Cave editor using [Godot v4.2.2](https://godotengine.org/) and [godot_voxel module](https://github.com/Zylann/godot_voxel).

![screenshot1](PreviewImages/screenshot1.png)
![screenshot2](PreviewImages/screenshot2.png)

## Features
- Edit terrain tools:
  - Sphere.
  - Cube.
  - Blend ball.
  - Surface.
  - Flatten.
  - Mesh.
- Terrain changes are automatically saved in a file.
- World manager that allows to have multiple worlds.
- Terrain mesh export (only exports loaded area around the camera).

## Project binary releases
Windows:
- https://github.com/Piratux/CaveEditor/releases/latest

## Building from source
Guide how to build from source:
- Get following repositories:
  - Godot 4.2.2 stable: https://github.com/godotengine/godot/releases/tag/4.2.2-stable
  - Godot voxel module 1.2.0: https://github.com/Zylann/godot_voxel/releases/tag/v1.2.0
- Follow compilation guide here:
  - https://voxel-tools.readthedocs.io/en/latest/getting_the_module/#building-yourself
- Then build Godot editor and template versions. For simplicity, setup exact folder copy, then run each command in each folder copy.
- Build Godot editor:
```
scons
```
  - Build godot editor with debug symbols enabled (optional):
```
scons dev_build=yes
```
  - Build Godot template release (required to create final standalone executable):
```
scons target=template_release
```

### Helper script to setup build from source
https://github.com/Piratux/godot-voxel-setup

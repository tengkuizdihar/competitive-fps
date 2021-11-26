# Configuring Godot + VSCodium + NixOS

1. Configuring Godot
   1. Retrieve VSCodium absolute path using `whereis codium` and take notes of it.
   2. Open up editor settings from the Top Menu => Editor => Text Editor => External
   3. Check `Use External Editor`.
   4. Paste the absolute path of VSCodium into `Exec Path`.
   5. Fill `Exec Flags` with `{project} --goto {file}:{line}:{col}`.
2. Configuring VSCodium
   1. Retrieve Godot Engine absolute path using `whereis godot` and take notes of it.
   2. Download godot-tools from the extension manager.
   3. Open up the settings and fill `editor_path` with Godot Engine's absolute path.

Restart both of the editor and engines, then enjoy your newly made editor! Also, now you could start up the debugger and use the breakpoint using `F5`.
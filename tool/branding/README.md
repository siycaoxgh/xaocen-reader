# Branding assets

`assets/branding/xaocen-reader-source.ico` is the checked-in source of truth
for the XAOCEN Reader logo.

For Android Adaptive Icons, the foreground must contain only the orange mark
with transparent pixels. The white rounded background is declared separately
in `mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml`.

Regenerate the Android resources after replacing the source ICO with:

```powershell
python tool/branding/generate_android_icons.py
```

The script intentionally keeps the logo well inside Android's adaptive-icon
safe zone. The transparent foreground therefore leaves an intentional white
ring around the orange mark on circular/squircle launchers; this is not a
second mask or a crop. Windows continues to use
`windows/runner/resources/app_icon.ico`.

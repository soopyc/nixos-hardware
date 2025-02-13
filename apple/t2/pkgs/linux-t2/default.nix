{
  lib,
  fetchurl, # fetchpatch does unnecessary normalization
  linux_6_13,
  ...
}@args:
let
  inherit (builtins) readFile fromJSON;
  inherit (lib.kernel) module yes;

  patches = map (patch: {
    inherit (patch) name;
    patch = fetchurl patch;
  }) (fromJSON (readFile ./patches.json));
in
linux_6_13.override (
  args
  // {
    pname = "linux-t2";

    structuredExtraConfig = {
      APPLE_BCE = module;
      APPLE_GMUX = module;
      APFS_FS = module;
      BRCMFMAC = module;
      BT_BCM = module;
      BT_HCIBCM4377 = module;
      BT_HCIUART_BCM = yes;
      BT_HCIUART = module;
      HID_APPLETB_BL = module;
      HID_APPLETB_KBD = module;
      HID_APPLE = module;
      DRM_APPLETBDRM = module;
      HID_SENSOR_ALS = module;
      SND_PCM = module;
      STAGING = yes;
    };

    kernelPatches = patches;

  }
  // (args.argsOverride or { })
)

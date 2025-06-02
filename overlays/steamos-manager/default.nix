final: prev: {
  steamos-manager = prev.steamos-manager.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches ++ [ ./allow_no_tdp_conf.patch ];
  });
}

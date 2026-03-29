final: prev: {
  intune-portal = prev.intune-portal.overrideAttrs (old: rec {
    version = "1.2603.31-noble";
    src = prev.fetchurl {
      url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/i/intune-portal/intune-portal_${version}_amd64.deb";
      hash = "sha256-0braaXnRa04CUQdJx0ZFwe5qfjsJNzTtGqaKQV5Z6Yw=";
    };
  });
}

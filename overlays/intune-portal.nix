final: prev:
{
  # Override intune-portal to test 1.2508.17 (reports of 1.2511.7 crashes)
  intune-portal = prev.intune-portal.overrideAttrs (old: rec {
    version = "1.2508.17-noble";
    src = prev.fetchurl {
      url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/i/intune-portal/intune-portal_${version}_amd64.deb";
      hash = "sha256-UTP+Z6xsjr48deizuwVDb8GrpeeAf5RZwloXsZ7Um3E=";
    };
  });
}

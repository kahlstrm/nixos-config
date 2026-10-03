{ pkgs }:
pkgs.dockerTools.buildLayeredImage {
  name = "harbor.kube.kalski.xyz/library/iperf3";
  tag = pkgs.iperf3.version;
  extraCommands = "mkdir -m 1777 tmp";
  config = {
    Entrypoint = [ "${pkgs.iperf3}/bin/iperf3" ];
    Cmd = [ "--server" ];
    User = "65532:65532";
    ExposedPorts = {
      "5201/tcp" = { };
      "5202/tcp" = { };
    };
  };
}

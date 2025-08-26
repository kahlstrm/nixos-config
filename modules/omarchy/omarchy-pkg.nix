{ pkgs }:
let
  version = "2.0.0";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "omarchy";
  inherit version;

  src = pkgs.fetchFromGitHub {
    owner = "basecamp"; # or your fork
    repo = "omarchy";
    rev = "v${version}"; # or a commit SHA
    sha256 = "sha256-n0CXgP23iZOOB7Q909lsQzLCHy+/DbFg/dNbvNsLFZg=";
  };

  # We only need the runtime assets and scripts that configs reference.
  # Copy them into $out in the same layout used by ~/.local/share/omarchy.
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
            runHook preInstall

            mkdir -p "$out"

            # Core trees
            for d in bin config default themes; do
              if [ -e "$d" ]; then
                cp -r "$d" "$out/"
              fi
            done

            # Branding/assets that some scripts reference
            for f in logo.txt logo.svg icon.txt README.md; do
              if [ -e "$f" ]; then
                cp -r "$f" "$out/"
              fi
            done
            # Remove Install/Remove/Update entries from the menu; managed by Nix
            substituteInPlace "$out/bin/omarchy-menu" \
              --replace-fail "Install\n󰭌  Remove\n  Update\n " "";
            substituteInPlace "$out/bin/omarchy-restart-app" \
              --replace-fail "pkill -x \$1" "pkill -fo \$1";

            substituteInPlace "$out/bin/omarchy-cmd-screensaver" \
              --replace-fail "pgrep -x tte" "pgrep -x .tte-wrapped" \
              --replace-fail "pkill -x tte" "pkill -x .tte-wrapped";

            substituteInPlace "$out/default/hypr/autostart.conf" \
              --replace-fail \
            "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" \
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

            # Replace Impala (iwd UI) with nmtui (NetworkManager TUI) at packaging time
            # Waybar: network module click action -> nmtui
            if [ -f "$out/config/waybar/config.jsonc" ]; then
              substituteInPlace "$out/config/waybar/config.jsonc" \
                --replace-fail "alacritty --class=Impala -e impala" "alacritty --class=Nmtui -e nmtui"
              # Inject Hyprland language module and place it second in modules-right
              tmpcfg=$(mktemp)
              ${pkgs.jq}/bin/jq '
                .["modules-right"] = (
                  (.["modules-right"] // []) as $mr
                  | ($mr | map(select(. != "hyprland/language"))) as $arr
                  | if ($arr|length) == 0 then ["hyprland/language"]
                    elif ($arr|length) == 1 then [$arr[0], "hyprland/language"]
                    else [$arr[0], "hyprland/language"] + ($arr[1:])
                    end
                )
                | .["hyprland/language"] = (.["hyprland/language"] // {
                    "format": "{}",
                    "format-en": "us",
                    "format-fi": "fi",
                    "on-click": "hyprctl switchxkblayout all next"
                  })
              ' "$out/config/waybar/config.jsonc" >"$tmpcfg" && mv "$tmpcfg" "$out/config/waybar/config.jsonc"
              # Ensure style for language module exists
              if ! grep -q '^#language' "$out/config/waybar/style.css" 2>/dev/null; then
                cat >> "$out/config/waybar/style.css" <<'EOF'

    #language {
      min-width: 12px;
      margin: 0 7.5px;
    }
    EOF
              fi
            fi
            # Omarchy main menu: Setup → Wifi -> nmtui
            if [ -f "$out/bin/omarchy-menu" ]; then
              substituteInPlace "$out/bin/omarchy-menu" \
                --replace-fail "alacritty --class=Impala -e impala" "alacritty --class=Nmtui -e nmtui"
            fi
            # Hypr window rules: float Nmtui instead of Impala
            if [ -f "$out/default/hypr/apps/system.conf" ]; then
              substituteInPlace "$out/default/hypr/apps/system.conf" \
                --replace-fail "Impala" "Nmtui"
            fi

            # Force launchers to use Brave from Nix store
            # omarchy-launch-browser: open Brave with any passed args
            cat > "$out/bin/omarchy-launch-browser" <<'EOF'
    #!/usr/bin/env bash
    exec setsid uwsm app -- ${pkgs.brave}/bin/brave "$@"
    EOF
            chmod +x "$out/bin/omarchy-launch-browser"

            # omarchy-launch-webapp: open URL in Brave app window
            cat > "$out/bin/omarchy-launch-webapp" <<'EOF'
    #!/usr/bin/env bash
    exec setsid uwsm app -- ${pkgs.brave}/bin/brave --app="$1" "''${@:2}"
    EOF
            chmod +x "$out/bin/omarchy-launch-webapp"

            # Drop binaries that perform imperative install/remove/update actions,
            # plus the version helper which we don't need in Nix builds.
            rm -f "$out/bin/omarchy-version"
            rm -f "$out/bin/"omarchy-install*
            rm -f "$out/bin/"omarchy-remove*
            rm -f "$out/bin/"omarchy-update*
            rm -f "$out/bin/"omarchy-pkg-*
            rm -f "$out/bin/"omarchy-migrate

            runHook postInstall
  '';
}

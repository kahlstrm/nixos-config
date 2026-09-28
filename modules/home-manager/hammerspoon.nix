{ flakeRoot, ... }:
{
  # Grant Hammerspoon Accessibility permission manually on each Mac.
  home.file.".hammerspoon/init.lua" = {
    source = flakeRoot + /config/hammerspoon/init.lua;
    onChange = ''
      if [ -d /Applications/Hammerspoon.app ]; then
        run /usr/bin/open -g -a /Applications/Hammerspoon.app 'hammerspoon://reload-config'
      fi
    '';
  };

  launchd.agents.hammerspoon = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-a"
        "/Applications/Hammerspoon.app"
      ];
      RunAtLoad = true;
      LimitLoadToSessionType = "Aqua";
    };
  };
}

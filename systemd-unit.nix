{ pkgs, ... }: {
  # stable-diffusion-webui is the name of the new service we'll be creating
  systemd.services.stable-diffusion-webui = {
     # This service is "wanted by" (see systemd man pages, or other tutorials)
     # the system level that allows multiple users to login and interact with
     # the machine non-graphically (see the Red Hat tutorial or Arch Linux Wiki
     # for more information on what each target means) this is the "node" in the
     # systemd dependency graph that will run the service.
     wantedBy = [ "multi-user.target" ];
     # The systemd service unit declarations involve specifying dependencies and
     # order of execution of systemd nodes; here we are saying that we want our
     # service to start after the network has set up.
     after = [ "network.target" ];
     description = "A machine learning image generator using Stable Diffusion.";
     serviceConfig = {
       # See systemd man pages for more information on the various options for
       # "Type": "notify" specifies that this is a service that waits for
       # notification from its predecessor (declared in `after=`) before
       # starting.
       Type = "notify";
       # The username that systemd will look for; if it exists, it will start a
       # service associated with that user.
       User = "username";
       # The command to execute when the service starts up.
       ExecStart =
         ''${pkgs.stable-diffusion-webui}/webui.sh'';
       # The command to execute.
       # ExecStop = ''${pkgs.screen}/bin/screen -S irc -X quit'';
       KillSignal = "SIGINT";
       Restart = "always";
       RestartSec = "15s";
     };
  };
  environment.systemPackages = [ ./stable-diffusion-webui.nix ];
}

{ pkgs, ... }: {
  # stable-diffusion-webui is the name of the new service we'll be creating
  launchd.agents.stable-diffusion-webui = {
    command = ''${pkgs.stable-diffusion-webui}/webui.sh'';
    path = pkgs.stable-diffusion-webui;
    # What's the difference between script and command?  Descriptions are
    # simiilar.
    script = ''${pkgs.stable-diffusion-webui}/webui.sh'';
    description = "A machine learning image generator using Stable Diffusion.";
    serviceConfig = {
    };
  };
  environment.systemPackages = [ ./stable-diffusion-webui.nix ];
}

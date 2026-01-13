{pkgs, ...}: {
  # Enable Fontconfig for proper font rendering
  fonts.fontconfig.enable = true;

  # Install Fira Code Nerd Font
  home.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  # Optional: You can add more specific font configurations here
  # For example, if you wanted to define specific font aliases or preferences
  # fonts.fontconfig.localConf = ''
  #   <?xml version="1.0"?>
  #   <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  #   <fontconfig>
  #     <match target="font">
  #       <edit name="hinting" mode="assign">
  #         <bool>true</bool>
  #       </edit>
  #     </match>
  #   </fontconfig>
  # '';
}

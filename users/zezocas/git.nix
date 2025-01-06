{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "zezocas";
        email = "the.jprp@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };
}

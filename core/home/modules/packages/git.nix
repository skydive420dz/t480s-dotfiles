{
  programs.git = {
    enable = true;
    settings = {
      commit.gpgSign = false;
      tag.gpgSign = false;
      user = {
        name = "Rafael Oliveira";
        email = "r0liveira@icloud.com";
      };
    };
  };
}

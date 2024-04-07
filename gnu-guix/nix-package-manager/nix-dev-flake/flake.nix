{
  inputs = {
    # Java (replace with specific version if needed)
    java = pkgs.jdk;

    # Clojure
    clojure = pkgs.clojure;

    # Android SDK tools
    android-sdk = github.com/tadfisher/android-nixpkgs; # Replaces default SDK

    # Dart SDK (replace with specific version if needed)
    #dart = pkgs.dart;

    # Flutter SDK (replace with specific version if needed)
    flutter = fetchFromGitHub {
      owner = "flutter";
      repo = "flutter";
      rev = "master"; # or specific version tag
    };

    # Visual Studio Code Insiders
    vscode-insiders = pkgs.vscode-insiders;

    # ClojureDart
    clojuredart = github.com:tensegritics/clojuredart; # Corrected repository
  };
};

outputs = {
  self.vscode = pkgs.writeScriptBin "vscode" "${vscode-insiders}/bin/code";
};
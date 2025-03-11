mkdir -p $HOME/dotnet && tar zxf dotnet-sdk-9.0.200-linux-x64.tar.gz -C $HOME/dotnet
export DOTNET_ROOT=$HOME/dotnet
export PATH=$PATH:$HOME/dotnet

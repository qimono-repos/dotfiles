# .NET / Q# helpers (dotnet usually from apt/Microsoft on this host)

if [[ -d /usr/lib/dotnet ]]; then
  export DOTNET_ROOT="${DOTNET_ROOT:-/usr/lib/dotnet}"
  path=("$DOTNET_ROOT" $path)
fi

# User-local dotnet tools
if [[ -d "$HOME/.dotnet/tools" ]]; then
  path=("$HOME/.dotnet/tools" $path)
fi

typeset -U path PATH
export PATH

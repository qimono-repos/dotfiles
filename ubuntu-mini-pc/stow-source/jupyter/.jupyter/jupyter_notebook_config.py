# Jupyter Notebook / Server config — managed by Stow (stow-source/jupyter).
# Applied path: ~/.jupyter/jupyter_notebook_config.py
#
# Bind local-only on a fixed port. Do not expose on LAN.
# Guix package: `jupyter` (classic Notebook on jupyter_server).
#
# Auth (password hash, token policy) is machine-local and never stowed:
#   ~/.secrets/jupyter_auth.py
# Create it with:  scripts/setup-jupyter-auth.sh

c = get_config()  # noqa: F821

c.ServerApp.ip = "127.0.0.1"
c.ServerApp.port = 5005
c.ServerApp.port_retries = 0
c.ServerApp.open_browser = False

c.NotebookApp.ip = "127.0.0.1"
c.NotebookApp.port = 5005
c.NotebookApp.port_retries = 0
c.NotebookApp.open_browser = False


def _load_local_jupyter_auth(c):
    """Load ~/.secrets/jupyter_auth.py if present (password hash, token, …)."""
    from pathlib import Path

    auth_path = Path.home() / ".secrets" / "jupyter_auth.py"
    if not auth_path.is_file():
        return

    try:
        mode = auth_path.stat().st_mode & 0o777
        if mode & 0o077:
            import sys

            print(
                f"warning: {auth_path} mode is {oct(mode)}; prefer chmod 600",
                file=sys.stderr,
            )
    except OSError:
        pass

    ns = {"c": c, "get_config": get_config}  # noqa: F821
    code = compile(auth_path.read_text(encoding="utf-8"), str(auth_path), "exec")
    exec(code, ns, ns)  # noqa: S102 — intentional load of user-owned secrets file


_load_local_jupyter_auth(c)

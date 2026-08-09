# Jupyter Notebook / Server config — managed by Stow (stow-source/jupyter).
# Applied path: ~/.jupyter/jupyter_notebook_config.py
#
# Bind local-only on a fixed port. Do not expose on LAN.
# Guix package: `jupyter` (classic Notebook on jupyter_server).

c = get_config()  # noqa: F821

# Modern Jupyter Server traits (notebook ≥6 / jupyter_server)
c.ServerApp.ip = "127.0.0.1"
c.ServerApp.port = 5005
c.ServerApp.port_retries = 0
c.ServerApp.open_browser = False

# Older NotebookApp names (still accepted on Guix notebook 6.x)
c.NotebookApp.ip = "127.0.0.1"
c.NotebookApp.port = 5005
c.NotebookApp.port_retries = 0
c.NotebookApp.open_browser = False

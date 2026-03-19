# Godot Auth Server

## Start headless auth server

```bash
./authServer/start_auth_server.sh
```

Optional settings:

```bash
BIND_HOST=0.0.0.0 AUTH_PORT=7001 PUBLIC_AUTH_HOST=auth.example.com ./authServer/start_auth_server.sh
```

Defaults come from `shared/host.config`:

```ini
[server]
bind_host="0.0.0.0"
public_auth_host="127.0.0.1"
auth_port=7001
```

`BIND_HOST`, `AUTH_PORT`, and `PUBLIC_AUTH_HOST` override that file.

The script runs Godot with:

```bash
--headless --path authServer res://AuthServerMain.tscn -- --bind-host=<BIND_HOST> --auth-port=<AUTH_PORT>
```

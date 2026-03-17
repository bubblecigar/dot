# Godot Auth Server

## Start headless auth server

```bash
./authServer/start_auth_server.sh
```

Optional settings:

```bash
AUTH_PORT=7001 ./authServer/start_auth_server.sh
```

Defaults come from `shared/host.config`:

```ini
[server]
auth_port=7001
```

`AUTH_PORT` overrides that file.

The script runs Godot with:

```bash
--headless --path authServer res://AuthServerMain.tscn -- --auth-port=<AUTH_PORT>
```

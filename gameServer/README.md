# Godot Game Server

## Start headless realtime server

```bash
./gameServer/start_game_server.sh
```

Optional settings:

```bash
GAME_PORT=7000 MAX_CLIENTS=64 PUBLIC_GAME_HOST=game.example.com PUBLIC_AUTH_HOST=auth.example.com AUTH_UPSTREAM_HOST=127.0.0.1 ./gameServer/start_game_server.sh
```

Defaults come from `shared/host.config`:

```ini
[server]
bind_host="0.0.0.0"
public_game_host="127.0.0.1"
public_auth_host="127.0.0.1"
auth_upstream_host="127.0.0.1"
game_port=7000
max_clients=32
```

`GAME_PORT`, `MAX_CLIENTS`, `PUBLIC_GAME_HOST`, `PUBLIC_AUTH_HOST`, and `AUTH_UPSTREAM_HOST` environment variables override that file.

The script runs Godot with:

```bash
--headless --path gameServer res://ServerMain.tscn -- --port=<PORT> --max-clients=<MAX_CLIENTS>
```

`gameServer/server_main.gd` reads the port/max-client user args, while `shared/network_config.gd` reads the public host values and auth upstream host from env vars or `shared/host.config`.

`ENetMultiplayerPeer.create_server()` listens on all interfaces, so there is no separate game-server bind-host setting here.

Run the auth service separately with [`authServer/start_auth_server.sh`](/Users/roy.wang/Desktop/daily/dot/authServer/start_auth_server.sh).

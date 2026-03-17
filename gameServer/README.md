# Godot Game Server

## Start headless realtime server

```bash
./gameServer/start_game_server.sh
```

Optional settings:

```bash
PORT=7000 MAX_CLIENTS=64 ./gameServer/start_game_server.sh
```

Defaults come from `shared/host.config`:

```ini
[server]
host="127.0.0.1"
port=7000
max_clients=32
```

`PORT`/`MAX_CLIENTS` environment variables override that file.

The script runs Godot with:

```bash
--headless --path gameServer res://ServerMain.tscn -- --port=<PORT> --max-clients=<MAX_CLIENTS>
```

`gameServer/server_main.gd` reads those user args and boots `gameServer/enet_server.gd` from the dedicated game server project.

Run the auth service separately with [`authServer/start_auth_server.sh`](/Users/roy.wang/Desktop/daily/dot/authServer/start_auth_server.sh).

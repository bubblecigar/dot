# Godot ENet Server

## Start headless realtime server

```bash
./server/start_enet_server.sh
```

Optional settings:

```bash
PORT=7000 MAX_CLIENTS=64 ./server/start_enet_server.sh
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
--headless --path . server/ServerMain.tscn -- --port=<PORT> --max-clients=<MAX_CLIENTS>
```

`server/server_main.gd` reads those user args and boots `server/enet_server.gd`.

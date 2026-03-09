# Godot ENet Server

## Start headless realtime server

```bash
./server/start_enet_server.sh
```

Optional settings:

```bash
PORT=7000 MAX_CLIENTS=64 ./server/start_enet_server.sh
```

The script runs Godot with:

```bash
--headless --path . server/ServerMain.tscn -- --port=<PORT> --max-clients=<MAX_CLIENTS>
```

`server/server_main.gd` reads those user args and boots `server/enet_server.gd`.

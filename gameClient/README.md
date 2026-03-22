# Game Client

## Start the client

From the repo root:

```bash
./gameClient/start_game_client.sh
```

Or from inside [gameClient](/Users/roy.wang/Desktop/daily/dot/gameClient):

```bash
./start_game_client.sh
```

The launcher resolves `godot` / `godot4` automatically and starts the client with `CONFIG_ENV=local` by default.

## Pass init credentials

You can auto-fill and auto-submit the login form from the launcher:

```bash
./gameClient/start_game_client.sh --init-username=user1@example.com --init-password=pass1
```

Or with env vars:

```bash
INIT_USERNAME=user1@example.com INIT_PASSWORD=pass1 ./gameClient/start_game_client.sh
```

## Multiplayer dev with two clients

Use [ecosystem.client.dev.cjs](/Users/roy.wang/Desktop/daily/dot/ecosystem.client.dev.cjs) to launch two client processes with PM2:

```bash
CLIENT_1_USERNAME=user1@example.com \
CLIENT_1_PASSWORD=pass1 \
CLIENT_2_USERNAME=user2@example.com \
CLIENT_2_PASSWORD=pass2 \
pm2 start ecosystem.client.dev.cjs --env local
```

Useful PM2 commands:

```bash
pm2 ls
pm2 logs gameClient1
pm2 logs gameClient2
pm2 delete gameClient1 gameClient2
```

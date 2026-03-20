# Local Override Test Commands

Use these commands to verify that env-var overrides still work across the auth server, game server, and client.

## 1. Auth Server

```bash
cd /Users/roy.wang/Desktop/daily/dot
BIND_HOST=0.0.0.0 AUTH_PORT=8124 PUBLIC_AUTH_HOST=127.0.0.1 ./authServer/start_auth_server.sh
```

Expected startup log:

```text
Auth server started on 0.0.0.0:8124
```

## 2. Game Server

```bash
cd /Users/roy.wang/Desktop/daily/dot
GAME_PORT=8123 AUTH_PORT=8124 PUBLIC_GAME_HOST=127.0.0.1 PUBLIC_AUTH_HOST=127.0.0.1 AUTH_UPSTREAM_HOST=127.0.0.1 MAX_CLIENTS=32 ./gameServer/start_game_server.sh
```

Expected startup log:

```text
ENet server started on port 8123
```

## 3. Client

Env-only override:

```bash
cd /Users/roy.wang/Desktop/daily/dot/gameClient
PUBLIC_GAME_HOST=127.0.0.1 PUBLIC_AUTH_HOST=127.0.0.1 GAME_PORT=8123 AUTH_PORT=8124 godot --path .
```

If your machine uses `godot4` instead:

```bash
cd /Users/roy.wang/Desktop/daily/dot/gameClient
PUBLIC_GAME_HOST=127.0.0.1 PUBLIC_AUTH_HOST=127.0.0.1 GAME_PORT=8123 AUTH_PORT=8124 godot4 --path .
```

CLI-arg override test:

```bash
cd /Users/roy.wang/Desktop/daily/dot/gameClient
PUBLIC_GAME_HOST=bad.example.com PUBLIC_AUTH_HOST=bad.example.com GAME_PORT=9999 AUTH_PORT=9998 godot --path . -- --server-host=127.0.0.1 --server-port=8123 --auth-host=127.0.0.1 --auth-port=8124
```

This verifies that client user args still override env vars.

## Optional Port Checks

From another terminal:

```bash
lsof -nP -iTCP:8123 -sTCP:LISTEN
lsof -nP -iTCP:8124 -sTCP:LISTEN
nc -vz 127.0.0.1 8124
```


# PUBLIC
1. client
```
cd /Users/roy.wang/Desktop/daily/dot/gameClient
godot --path . -- --auth-host=198.13.54.180 --auth-port=7001 --server-host=198.13.54.180 --server-port=7000
```

2. GameServer on VPS root
```
cd ~/dot/gameServer
../Godot_v4.6.1-stable_linux.x86_64 --headless --path .
```

3. AuthServer on VPS
```
cd ~/dot/authServer
../Godot_v4.6.1-stable_linux.x86_64 --headless --path .
```

# PM2
Use [ecosystem.config.cjs](/Users/roy.wang/Desktop/daily/dot/ecosystem.config.cjs) to run the auth server and game server in the background.

Local environment:
```bash
cd /Users/roy.wang/Desktop/daily/dot
pm2 start ecosystem.config.cjs --env local
```

Production environment:
```bash
cd /root/dot
pm2 start ecosystem.config.cjs --env prod
```

Common PM2 commands:
```bash
pm2 status
pm2 logs authServer
pm2 logs gameServer
pm2 restart ecosystem.config.cjs --env prod
pm2 save
pm2 startup
```

# Deploy
Use [deploy_vps.sh](/Users/roy.wang/Desktop/daily/dot/scripts/deploy_vps.sh) to upload the repo to the VPS and restart the PM2-managed servers.

Production deploy:
```bash
cd /Users/roy.wang/Desktop/daily/dot
REMOTE_HOST=198.13.54.180 REMOTE_USER=root REMOTE_DIR=/root/dot PM2_ENV=prod ./scripts/deploy_vps.sh
```

Optional overrides:
```bash
REMOTE_HOST=198.13.54.180
REMOTE_USER=root
REMOTE_DIR=/root/dot
PM2_ENV=prod
SSH_OPTS="-i ~/.ssh/your_key"
```

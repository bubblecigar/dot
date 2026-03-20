module.exports = {
  apps: [
    {
      name: "authServer",
      cwd: __dirname,
      script: "./authServer/start_auth_server.sh",
      interpreter: "/bin/bash",
      autorestart: true,
      restart_delay: 3000,
      env_local: {
        BIND_HOST: "0.0.0.0",
        AUTH_PORT: "7001",
        PUBLIC_AUTH_HOST: "127.0.0.1",
      },
      env_prod: {
        BIND_HOST: "0.0.0.0",
        AUTH_PORT: "7001",
        PUBLIC_AUTH_HOST: "198.13.54.180",
      },
    },
    {
      name: "gameServer",
      cwd: __dirname,
      script: "./gameServer/start_game_server.sh",
      interpreter: "/bin/bash",
      autorestart: true,
      restart_delay: 3000,
      env_local: {
        GAME_PORT: "7000",
        AUTH_PORT: "7001",
        PUBLIC_GAME_HOST: "127.0.0.1",
        PUBLIC_AUTH_HOST: "127.0.0.1",
        AUTH_UPSTREAM_HOST: "127.0.0.1",
        MAX_CLIENTS: "32",
      },
      env_prod: {
        GAME_PORT: "7000",
        AUTH_PORT: "7001",
        PUBLIC_GAME_HOST: "198.13.54.180",
        PUBLIC_AUTH_HOST: "198.13.54.180",
        AUTH_UPSTREAM_HOST: "127.0.0.1",
        MAX_CLIENTS: "32",
      },
    },
  ],
};

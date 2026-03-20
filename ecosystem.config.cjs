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
        GODOT_BIN: "godot",
        CONFIG_ENV: "local",
      },
      env_prod: {
        GODOT_BIN: "/root/dot/Godot_v4.6.1-stable_linux.x86_64",
        CONFIG_ENV: "prod",
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
        GODOT_BIN: "godot",
        CONFIG_ENV: "local",
      },
      env_prod: {
        GODOT_BIN: "/root/dot/Godot_v4.6.1-stable_linux.x86_64",
        CONFIG_ENV: "prod",
      },
    },
  ],
};

module.exports = {
  apps: [
    {
      name: "pacepilot",
      script: "uvicorn",
      args: "main:app --host 0.0.0.0 --port 8000",
      interpreter: "none",
      cwd: "./pacepilot-server",
    },
  ],
};

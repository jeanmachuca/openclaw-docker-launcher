# If the gateway is running, setup may race on dist-runtime; see README (first-time setup).
docker compose --profile openclaw exec -w /app/openclaw openclaw pnpm openclaw setup
until ./restart.sh > /dev/null 2>&1; do
    echo "Waiting for the system to be ready..."
    sleep 5
done
echo "✅ System is ready (first boot: openclaw setup runs in the container before the gateway)."
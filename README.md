# T3rn Node Manager

A bash script for managing T3rn executor nodes with easy installation and maintenance capabilities.

## Features

- 🚀 Easy node installation and updates
- 📊 Real-time log monitoring
- 💰 Dynamic gas fee adjustment
- 🔄 Automatic node restart functionality
- 🛠 Version management
- 🗑️ Clean uninstallation

## Prerequisites

- Ubuntu/Debian-based Linux system
- Sudo privileges
- Required packages:
  - make
  - screen
  - build-essential
  - software-properties-common
  - curl
  - git
  - nano
  - jq

## Installation

1. Download the script:
```bash
wget https://raw.githubusercontent.com/dsadwqeqeasad/ternNode/main/t3rnNodeManager.sh
chmod +x ternNodeManager.sh
```

2. Run the script:
```bash
./ternNodeManager.sh
```

## Menu Options

1. **Install Node** - Install a new T3rn executor node
2. **Stop Node** - Stop the running node
3. **Restart Node** - Restart the node
4. **Auto Restart Node** - Enable automatic restart every 2 hours
5. **Update Node version** - Update to the latest or specific version
6. **Uninstall Node** - Remove the node completely
7. **Logs** - View node logs
8. **Change Fee** - Adjust gas fee settings
9. **Exit** - Exit the script

## Configuration

### Environment Variables

```bash
ENVIRONMENT="testnet"
LOG_LEVEL="debug"
LOG_PRETTY="false"
EXECUTOR_PROCESS_BIDS_ENABLED=true
EXECUTOR_PROCESS_ORDERS_ENABLED=true
EXECUTOR_PROCESS_CLAIMS_ENABLED=true
ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'
```

### RPC Endpoints

The script includes pre-configured RPC endpoints for:
- L2RN
- Arbitrum Sepolia
- Base Sepolia
- Optimism Sepolia
- Unichain
- Blast Sepolia

## Usage Examples

### Installing a Node
```bash
./ternNodeManager.sh
# Select option 1
# Enter your private key when prompted
```

### Changing Gas Fee
```bash
./ternNodeManager.sh
# Select option 8
# Enter new gas price in GWEI
```

### Viewing Logs
```bash
./ternNodeManager.sh
# Select option 7
```

## Automatic Restart

The script includes an auto-restart feature that:
- Creates a screen session named 't3rnnode_auto'
- Restarts the node every 2 hours
- Persists across system reboots via crontab

## Troubleshooting

### Common Issues

1. **Node Won't Start**
   - Check if the executor folder exists
   - Verify your private key
   - Check screen session status

2. **Screen Session Issues**
   - Run `screen -ls` to check existing sessions
   - Kill stuck sessions with `screen -X -S [session] quit`

3. **Permission Issues**
   - Ensure script has execute permissions
   - Run with sudo when required

## Security Notes

- Store your private key securely
- Don't share screen session details
- Regularly update node version
- Monitor logs for suspicious activity

## Contributing

Feel free to submit issues and enhancement requests!

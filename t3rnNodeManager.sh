update_node() {
  delete_node

  if [ -d "$HOME/executor" ] || screen -list | grep -q "\.t3rnnode"; then
    echo 'Folder executor or session t3rnnode has been installed before. Installation is impossible. Choose to delete the node or exit the script.'
    return
  fi

  echo 'Updating the node...'

  read -p "Your private key: " PRIVATE_KEY_LOCAL

  download_or_update
}

download_node() {
  if [ -d "$HOME/executor" ] || screen -list | grep -q "\.t3rnnode"; then
    echo 'Folder executor or session t3rnnode has been installed before. Installation is impossible. Choose to delete the node or exit the script.'
    return
  fi

  echo 'Installing the node...'

  read -p "Your private key: " PRIVATE_KEY_LOCAL

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install make screen build-essential software-properties-common curl git nano jq -y

  download_or_update
}

download_or_update() {
  cd $HOME

  echo "Choose an option of installing:"
  echo "1) Last version"
  echo "2) Concrete version"
  read -p "Enter option (1 or 2): " CHOICE

  if [ "$CHOICE" = "1" ]; then
    sudo curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | \
      grep -Po '"tag_name": "\K.*?(?=")' | \
      xargs -I {} wget https://github.com/t3rn/executor-release/releases/download/{}/executor-linux-{}.tar.gz
    sudo tar -xzf executor-linux-*.tar.gz
    sudo rm -rf executor-linux-*.tar.gz
  elif [ "$CHOICE" = "2" ]; then
    read -p "Enter version (e.g., 54 for v0.54.0): " VERSION
    VERSION_FULL="v0.${VERSION}.0"
    sudo wget https://github.com/t3rn/executor-release/releases/download/${VERSION_FULL}/executor-linux-${VERSION_FULL}.tar.gz -O executor-linux.tar.gz
    sudo tar -xzvf executor-linux.tar.gz
    sudo rm -rf executor-linux.tar.gz
  else
    echo "Invalid choice. Installation cancelled."
    return
  fi

  cd executor

  export ENVIRONMENT="testnet"
  export LOG_LEVEL="debug"
  export LOG_PRETTY="false"
  export EXECUTOR_PROCESS_BIDS_ENABLED=true
  export EXECUTOR_PROCESS_ORDERS_ENABLED=true
  export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
  export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'
  export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"
  export EXECUTOR_ENABLE_BATCH_BIDING=true
  export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
  export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
  export EXECUTOR_ENABLE_BATCH_BIDDING=true
  export EXECUTOR_PROCESS_BIDS_BATCH=true
  export RPC_ENDPOINTS='{
      "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
      "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
      "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
      "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
      "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"],
      "bssp": ["https://base-sepolia-rpc.publicnode.com/", "https://sepolia.base.org"],
      "blst": ["https://blast-sepolia-rpc.example.com"]
  }'
  export EXECUTOR_MAX_L3_GAS_PRICE=1050

  cd $HOME/executor/executor/bin/

  screen -dmS t3rnnode bash -c '
    echo "Starting script execution in screen session..."

    cd $HOME/executor/executor/bin/
    ./executor

    exec bash
  '

  echo "Node installation completed successfully. Screen session 't3rnnode' created."
}

check_logs() {
  if screen -list | grep -q "\.t3rnnode"; then
    screen -S t3rnnode -X hardcopy -h /tmp/screen_log.txt
    sleep 0.1
    
    if [ -f /tmp/screen_log.txt ]; then
      echo "=== Last logs t3rnnode ==="
      echo "----------------------------------------"
      tail -n 40 /tmp/screen_log.txt | awk '{print "\033[0;32m" NR "\033[0m: " $0}'
      echo "----------------------------------------"
      echo "(time: $(date '+%H:%M:%S %d.%m.%Y'))"
      rm -f /tmp/screen_log.txt
    else
      echo "Error: Not able to extract logs from screen-session."
    fi
  else
    echo "Session t3rnnode not found."
  fi
}

change_fee() {
    echo 'Changing commission...'

    if [ ! -d "$HOME/executor" ]; then
        echo 'Folder executor not found. Install the node.'
        return
    fi

    session="t3rnnode"

    read -p 'Which gas of GWEI would you like? (default 1050) ' GWEI_SET

    if ! [[ "$GWEI_SET" =~ ^[0-9]+$ ]]; then
        echo "Error: Please enter a valid number"
        return
    fi

    if screen -list | grep -q "\.${session}"; then
      screen -S "${session}" -p 0 -X stuff "^C"
      sleep 1
      screen -S "${session}" -p 0 -X stuff "export EXECUTOR_MAX_L3_GAS_PRICE=$GWEI_SET\n"
      sleep 1
      screen -S "${session}" -p 0 -X stuff "./executor\n"
      echo 'Commission was changed.'
    else
      echo "Session ${session} not found. Gas cannot be changed"
      return
    fi
}

stop_node() {
  echo 'Stopping the node...'

  if screen -list | grep -q "\.t3rnnode"; then
    screen -S t3rnnode -p 0 -X stuff "^C"
    echo "Node was stopped."
  else
    echo "Session t3rnnode was not found."
  fi
}

auto_restart_node() {
  screen_name="t3rnnode_auto"
  script_path="$HOME/t3rn_restart.sh"

  if screen -list | grep -q "\.$screen_name"; then
    screen -X -S "$screen_name" quit
    echo "Existing screen '$screen_name' was stopped."
  fi

  cat > "$script_path" << 'EOF'
restart_node() {
  echo 'Reloading the node...'

  session="t3rnnode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "./executor\n"
    echo "Node was reloaded."
  else
    echo "Session ${session} not found."
  fi
}

while true; do
  restart_node
  sleep 7200
done
EOF
  chmod +x "$script_path"

  screen -dmS "$screen_name" bash "$script_path"
  echo "Screen-session '$screen_name' was created, the node is going to be restarted every 2h."

  (crontab -l 2>/dev/null | grep -v "$script_path"; echo "@reboot screen -dmS $screen_name bash $script_path") | crontab -
  echo "Task added to crontab."
}

restart_node() {
  echo 'Reloading the node...'

  session="t3rnnode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "./executor\n"
    echo "Node was restarted."
  else
    echo "Session ${session} not found."
  fi
}

delete_node() {
  echo 'Removing the node...'

  if [ -d "$HOME/executor" ]; then
    sudo rm -rf $HOME/executor
    echo "executor folder was deleted."
  else
    echo "executor folder not found."
  fi

  if screen -list | grep -q "\.t3rnnode"; then
    sudo screen -X -S t3rnnode quit
    echo "t3rnnode session was terminated."
  else
    echo "t3rnnode session was not found."
  fi

  sudo screen -X -S t3rnnode_auto quit

  echo "Node was uninstalled."
}

exit_from_script() {
  exit 0
}

while true; do
    echo -e "\nMenu:"
    echo "1. Install Node"
    echo "2. Stop Node"
    echo "3. Restart Node"
    echo "4. Auto Restart Node"
    echo "5. Update Node version"
    echo "6. Uninstall Node"
    echo "7. Logs"
    echo "8. Change Fee"
    echo -e "9. Exit\n"
    read -p "Option: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        stop_node
        ;;
      3)
        restart_node
        ;;
      4)
        auto_restart_node
        ;;
      5)
        update_node
        ;;
      6)
        delete_node
        ;;
      7)
        check_logs
        ;;
      8)
        change_fee
        ;;
      9)
        exit_from_script
        ;;
      *)
        echo "Invalid option. Choose option from menu."
        ;;
    esac
  done

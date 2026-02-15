#!/usr/bin/env bash
SERVER=10.0.0.2

echo "condition,cc,flows,value,unit" > final_results.csv

run_set () {
  local condition="$1"
  for cc in cubic bbr reno; do
    sudo ip netns exec ns_client sysctl -w net.ipv4.tcp_congestion_control=$cc >/dev/null
    out=$(sudo ip netns exec ns_client iperf3 -c "$SERVER" -t 15 -P 1 | awk '/receiver/{print $(NF-2), $(NF-1)}' | tail -n 1)
    val=$(echo "$out" | awk '{print $1}'); unit=$(echo "$out" | awk '{print $2}')
    echo "$condition,$cc,1,$val,$unit" >> final_results.csv
  done

  for cc in cubic bbr reno; do
    sudo ip netns exec ns_client sysctl -w net.ipv4.tcp_congestion_control=$cc >/dev/null
    out=$(sudo ip netns exec ns_client iperf3 -c "$SERVER" -t 15 -P 5 | awk '/SUM.*receiver/{print $(NF-2), $(NF-1)}' | tail -n 1)
    val=$(echo "$out" | awk '{print $1}'); unit=$(echo "$out" | awk '{print $2}')
    echo "$condition,$cc,5,$val,$unit" >> final_results.csv
  done
}

# 1) Normal
sudo ip netns exec ns_client tc qdisc del dev veth-c root 2>/dev/null || true
run_set "normal"

# 2) Constrained: 10Mbps + 50ms + 2% loss
sudo ip netns exec ns_client tc qdisc del dev veth-c root 2>/dev/null || true
sudo ip netns exec ns_client tc qdisc add dev veth-c root handle 1: tbf rate 10mbit burst 32kbit latency 400ms
sudo ip netns exec ns_client tc qdisc add dev veth-c parent 1:1 handle 10: netem delay 50ms loss 2%
run_set "delay50_loss2_bw10"

# Cleanup
sudo ip netns exec ns_client tc qdisc del dev veth-c root 2>/dev/null || true
echo "Done -> final_results.csv"

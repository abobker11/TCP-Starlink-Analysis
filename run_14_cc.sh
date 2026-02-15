#!/usr/bin/env bash
set -euo pipefail

SERVER_IP=10.0.0.2
DUR=60        # خليها 60 للتجربة الشاملة، وبعدها نقدر نرفعها 180 لأهم خوارزميات
FLOWS1=1
FLOWS2=10

ALGS=(cubic bbr bic cdg dctcp highspeed htcp hybla illinois lp nv scalable veno westwood)

echo "condition,cc,flows,value,unit"

run_iperf () {
  local cc="$1"
  local flows="$2"
  sudo ip netns exec ns_client iperf3 -c "$SERVER_IP" -t "$DUR" -P "$flows" -C "$cc" -J 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); bps=d['end']['sum_received']['bits_per_second']; print(f'{bps/1e9:.2f},Gbits/sec' if bps>=1e9 else f'{bps/1e6:.2f},Mbits/sec')"
}

# NORMAL
sudo ip netns exec ns_client tc qdisc del dev veth-c root 2>/dev/null || true
for cc in "${ALGS[@]}"; do
  out=$(run_iperf "$cc" "$FLOWS1")
  echo "normal,$cc,$FLOWS1,$out"
done
for cc in "${ALGS[@]}"; do
  out=$(run_iperf "$cc" "$FLOWS2")
  echo "normal,$cc,$FLOWS2,$out"
done

# IMPAIRED: bw10 + delay50 + loss2
sudo ip netns exec ns_client tc qdisc del dev veth-c root 2>/dev/null || true
sudo ip netns exec ns_client tc qdisc add dev veth-c root handle 1: tbf rate 10mbit burst 32kbit latency 400ms
sudo ip netns exec ns_client tc qdisc add dev veth-c parent 1:1 handle 10: netem delay 50ms loss 2%

for cc in "${ALGS[@]}"; do
  out=$(run_iperf "$cc" "$FLOWS1")
  echo "delay50_loss2_bw10,$cc,$FLOWS1,$out"
done
for cc in "${ALGS[@]}"; do
  out=$(run_iperf "$cc" "$FLOWS2")
  echo "delay50_loss2_bw10,$cc,$FLOWS2,$out"
done

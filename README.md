# TCP Congestion Control Performance under Starlink-like Impairments 🛰️

## 📌 Project Overview
This repository contains a **Replication Research** study conducted as part of an IT Master's program. The project evaluates and compares the performance of **14 different TCP Congestion Control Algorithms (CCAs)**—with a specific focus on **BBR vs. CUBIC**—under emulated Low Earth Orbit (LEO) satellite network conditions (similar to Starlink). 

Traditional loss-based CCAs (like CUBIC) often misinterpret non-congestion packet loss on satellite links as queue congestion, leading to poor throughput. This study investigates whether model-based algorithms (like BBR) provide superior performance and stability in such environments.

## 🛠️ Methodology & Emulation Environment
The testbed was built entirely on **Ubuntu 22.04** (Linux kernel 6.8.x) without requiring external hardware, using advanced Linux networking features:
* **Topology:** A client-server architecture isolated using **Linux Network Namespaces** (`ns_client` and `ns_server`) connected via a `veth` pair.
* **Traffic Generation:** End-to-end TCP throughput was measured using `iperf3`.
* **Impairment Model:** Starlink-like conditions were emulated on the client egress interface using Linux Traffic Control (`tc`):
  * **Bandwidth:** Limited to 10 Mbit/s using Token Bucket Filter (TBF).
  * **Delay & Loss:** 50 ms one-way delay and 2% random packet loss injected using `netem`.

## 📊 Key Findings
The study tested 14 CCAs (including bbr, cubic, bic, hybla, illinois, westwood, etc.) under single-flow ($P=1$) and multi-flow ($P=10$) scenarios.

1. **BBR Dominates Single-Flow (P=1):** Under impaired conditions (10 Mbit/s, 50ms, 2% loss), **BBR achieved $\approx5.96$ Mbit/s**, outperforming CUBIC ($\approx1.97$ Mbit/s) by nearly **3x**. BBR's pacing model proves highly robust against random packet loss.
2. **Multi-Flow Dynamics (P=10):** With 10 parallel flows, overall link utilization improves. BBR remained highly competitive ($\approx7.64$ Mbit/s), while CCAs like Westwood ($\approx7.75$ Mbit/s) showed slight leads due to their wireless-optimized mechanisms.
3. **Fairness:** In a mixed bottleneck scenario, BBR does not completely starve CUBIC, but tends to take a modestly larger share ($\approx58\%$) when it is the incumbent flow.

## 📁 Repository Structure
* `/docs`: Contains the full project report (`TCP_CC_Starlink_Report.pdf`).
* `/results`: CSV files containing raw `iperf3` data for all 14 CCAs.
* `/plots`: Graphical representations (bar charts) of throughput comparisons.

## 🚀 Reproducibility (Quick Start)
The environment can be reproduced using `iproute2` and `tc`. Here is a snippet of the core setup:

```bash
# 1. Setup Namespaces & Veth pair
sudo ip netns add ns_client
sudo ip netns add ns_server
sudo ip link add veth-c type veth peer name veth-s
# ... (Assign to namespaces and configure IPs: 10.0.0.1/24 and 10.0.0.2/24)

# 2. Apply Starlink Impairments (Rate limit + Delay + Loss)
sudo ip netns exec ns_client tc qdisc add dev veth-c root handle 1: tbf rate 10mbit burst 32kbit latency 400ms
sudo ip netns exec ns_client tc qdisc add dev veth-c parent 1:1 handle 10: netem delay 50ms loss 2%

# 3. Run Test (Example: BBR)
sudo ip netns exec ns_server iperf3 -s -D
sudo ip netns exec ns_client iperf3 -c 10.0.0.2 -t 180 -P 1 -C bbr

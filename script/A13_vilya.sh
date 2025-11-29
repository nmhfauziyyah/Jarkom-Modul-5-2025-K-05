#!/bin/bash

# ==========================================================
# KONFIGURASI VILYA (DHCP SERVER) - MODUL 5
# Subnet A13: 10.66.0.40/29
# Misi 1: DHCP Scopes | Misi 2: Block PING
# ==========================================================

echo "Mulai konfigurasi Vilya (DHCP Server)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static
# ----------------------------------------------------------------
echo "--- 1. Konfigurasi IP Static dan Instalasi ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Switch 1 (A13). Vilya IP: 10.66.0.43
auto eth0
iface eth0 inet static
    address 10.66.0.43
    netmask 255.255.255.248
    gateway 10.66.0.41 # Gateway adalah Rivendell
EOF

# Restart networking agar konfigurasi diterapkan
systemctl restart networking
sleep 5 # Beri jeda agar DHCP eth0 mendapat IP

# Konfigurasi DNS Server (Menggunakan IP NAT/Internet Host: 192.168.122.1)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Instalasi DHCP Server dan Iptables
apt update
apt install -y isc-dhcp-server iptables
echo "Jaringan dan instalasi selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 1 No. 4: Konfigurasi DHCP Scopes
# ----------------------------------------------------------------
echo "--- 2. Konfigurasi DHCP Scopes (/etc/dhcp/dhcpd.conf) ---"

# Set interface yang melayani DHCP Relay
sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

# Konfigurasi dhcpd.conf
cat << EOF > /etc/dhcp/dhcpd.conf
# File konfigurasi utama DHCP Server Vilya (10.66.0.43)
ddns-update-style none;
default-lease-time 600;
max-lease-time 3600;
authoritative;
log-facility local7;

# Opsi umum
option domain-name "K05.com";
option domain-name-servers 10.66.0.42; # Narya DNS
option subnet-mask 255.255.255.248; # Subnet mask default untuk A13, tapi akan ditimpa di scope

# --- Deklarasi Subnet (Non-Client, Vilya/Narya) ---
subnet 10.66.0.40 netmask 255.255.255.248 {
}

# ----------------------------------------
# Scope untuk CLIENT yang mendapat IP Otomatis
# ----------------------------------------

# 1. Subnet A11: Khamul (5 Host) - 10.66.0.32/29
subnet 10.66.0.32 netmask 255.255.255.248 {
    range 10.66.0.35 10.66.0.38; 
    option routers 10.66.0.33; # Gateway Khamul: Wilderland
    option broadcast-address 10.66.0.39;
}

# 2. Subnet A10: Durin (50 Host) - 10.66.0.64/26
subnet 10.66.0.64 netmask 255.255.255.192 {
    range 10.66.0.67 10.66.0.126; 
    option routers 10.66.0.65; # Gateway Durin: Wilderland
    option broadcast-address 10.66.0.127;
}

# 3. Subnet A5: Gilgalad & Cirdan (121 Host) - 10.66.0.128/25
subnet 10.66.0.128 netmask 255.255.255.128 {
    range 10.66.0.132 10.66.0.254; 
    option routers 10.66.0.129; # Gateway A5: AnduinBanks
    option broadcast-address 10.66.0.255;
}

# 4. Subnet A6: Elendil & Isildur (231 Host) - 10.66.1.0/24
subnet 10.66.1.0 netmask 255.255.255.0 {
    range 10.66.1.4 10.66.1.254; 
    option routers 10.66.1.1; # Gateway A6: Minastir/Swath4
    option broadcast-address 10.66.1.255;
}

# Deklarasi host static Palantir (10.66.0.14) dan IronHills (10.66.0.22)
host palantir { fixed-address 10.66.0.14; }
host ironhills { fixed-address 10.66.0.22; }

EOF

# Restart DHCP Server
service isc-dhcp-server restart
echo "Konfigurasi DHCP Scopes selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# C. Misi 2 No. 2: Firewall IPTABLES (Block PING)
# ----------------------------------------------------------------
echo "--- 3. Misi 2: Firewall Vilya (Block PING) ---"

# Reset aturan Iptables
iptables -F
iptables -X

# 1. Izinkan Loopback dan Established
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 2. Blokir PING (ICMP Echo Request) dari perangkat lain (Misi 2 No. 2)
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# 3. Izinkan akses DHCP (UDP Port 67 dan 68) agar DHCP Relay berfungsi
iptables -A INPUT -p udp --dport 67 -j ACCEPT
iptables -A INPUT -p udp --dport 68 -j ACCEPT

# 4. DROP sisanya (jika ada servis lain yang tidak diinginkan diakses)
iptables -A INPUT -j DROP

echo "Firewall Vilya selesai dikonfigurasi."
echo "========================================"


# ----------------------------------------------------------------
# D. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 4. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth0'

echo -e "\n=== KONFIRMASI STATUS DHCP SERVER ==="
service isc-dhcp-server status | grep 'Active'

echo -e "\n=== KONFIRMASI ATURAN IPTABLES (PING BLOCK) ==="
iptables -L INPUT -v -n | grep 'icmp'

echo -e "\n=== UJI PING KE GATEWAY (Rivendell 10.66.0.41) ==="
ping -c 3 10.66.0.41

echo -e "\n=== UJI PING KELUAR (8.8.8.8) ==="
ping -c 3 8.8.8.8

echo -e "\n!!! KONFIGURASI VILYA SELESAI !!!"
echo "Pastikan DHCP Relay di semua router aktif, lalu coba client Durin/Elendil/Gilgalad dhclient -v."
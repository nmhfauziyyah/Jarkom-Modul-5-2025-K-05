#!/bin/bash

# ==========================================================
# KONFIGURASI NARYA (DNS SERVER) - MODUL 5
# Subnet A13: 10.66.0.40/29
# Misi 2 No. 3: Akses DNS HANYA dari Vilya
# ==========================================================

echo "Mulai konfigurasi Narya (DNS Server)..."

# ----------------------------------------------------------------
# A. Misi 1 No. 3: Konfigurasi IP Static dan Instalasi DNS
# ----------------------------------------------------------------
echo "--- 1. Konfigurasi IP Static dan Instalasi BIND ---"

# Konfigurasi /etc/network/interfaces (IP Static)
cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# eth0: ke Switch 1 (A13). Narya IP: 10.66.0.42
auto eth0
iface eth0 inet static
    address 10.66.0.42
    netmask 255.255.255.248
    gateway 10.66.0.41 # Gateway adalah Rivendell
EOF
/etc/init.d/networking restart
sleep 2

# Konfigurasi DNS Server (Menggunakan IP NAT/Internet Host: 192.168.122.1)
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Instalasi DNS Server (BIND9)
apt update
apt install -y bind9 iptables

echo "Jaringan dan instalasi selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# B. Misi 1 No. 4: Konfigurasi DNS ZONA
# ----------------------------------------------------------------
echo "--- 2. Konfigurasi Zona BIND9 ---"

# 1. Konfigurasi named.conf.local (Deklarasi Zona)
cat << EOF > /etc/bind/named.conf.local
zone "K05.com" {
    type master;
    file "/etc/bind/K05.com";
};

zone "40.0.66.10.in-addr.arpa" { # KOREKSI: Gunakan 40.0.66.10 karena 10.66.0.40 adalah Network ID
    type master;
    file "/etc/bind/db.40"; # Nama file baru yang lebih spesifik
};
EOF

# 2. Konfigurasi Zona Forward (K05.com)
cat << EOF > /etc/bind/K05.com
\$TTL    604800
@       IN      SOA     K05.com. root.K05.com. (
                        2025112801 ; Serial (format YYYYMMDDXX)
                        604800     ; Refresh (1 minggu)
                        86400      ; Retry (1 hari)
                        2419200    ; Expire (4 minggu)
                        604800 )   ; Negative Cache TTL

@         IN      NS      Narya.K05.com.
@         IN      A       10.66.0.42
Narya     IN      A       10.66.0.42
Vilya     IN      A       10.66.0.43
Palantir  IN      A       10.66.0.14
IronHills IN      A       10.66.0.22
EOF

# 3. Konfigurasi Zona Reverse (40.0.66.10.in-addr.arpa)
cat << EOF > /etc/bind/db.40
\$TTL    604800
@       IN      SOA     K05.com. root.K05.com. (
                        2025112801 ; Serial
                        604800
                        86400
                        2419200
                        604800 )

@       IN      NS      Narya.K05.com.
42      IN      PTR     Narya.K05.com.
43      IN      PTR     Vilya.K05.com.
EOF

# Restart BIND
ln -s /etc/init.d/named /etc/init.d/bind9 # (Symlink opsional)
service bind9 restart
echo "Konfigurasi BIND9 selesai."
echo "----------------------------------------"


# ----------------------------------------------------------------
# C. Misi 2 No. 3: Firewall Iptables (Batasi Akses DNS)
# ----------------------------------------------------------------
echo "--- 3. Konfigurasi Firewall Iptables (Misi 2 No. 3) ---"

# Reset aturan Iptables
iptables -F
iptables -X

# 1. Izinkan Loopback dan Established
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 2. Aturan ACCEPT HANYA untuk Vilya (10.66.0.43)
# Hanya Vilya yang dapat mengakses Narya (DNS).
iptables -A INPUT -p udp --dport 53 -s 10.66.0.43 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -s 10.66.0.43 -j ACCEPT

# 3. DROP semua akses DNS lainnya (dari mana pun)
iptables -A INPUT -p udp --dport 53 -j DROP
iptables -A INPUT -p tcp --dport 53 -j DROP

# 4. DROP semua trafik sisa (termasuk PING dari luar, dll)
iptables -A INPUT -j DROP

echo "Firewall DNS selesai dikonfigurasi."
echo "========================================"


# ----------------------------------------------------------------
# D. Perintah Konfirmasi
# ----------------------------------------------------------------
echo "--- 4. Perintah Konfirmasi (Wajib Dijalankan) ---"

echo -e "\n=== KONFIRMASI IP ADDRESS ==="
ip a | grep 'eth0'

echo -e "\n=== KONFIRMASI STATUS BIND9 ==="
service bind9 status | grep 'Active'

echo -e "\n=== UJI DNS LOKAL (FORWARD) ==="
# Pastikan record forward bekerja
dig @127.0.0.1 Vilya.K05.com

echo -e "\n=== UJI DNS LOKAL (REVERSE) ==="
# Pastikan record reverse bekerja
dig @127.0.0.1 -x 10.66.0.43

echo -e "\n=== KONFIRMASI ATURAN IPTABLES (DNS HANYA VILYA) ==="
iptables -L INPUT -v -n

echo -e "\n=== UJI FIREWALL DNS (Misi 2 No. 3) ==="
echo "Untuk menguji firewall, Anda harus menjalankan perintah nc di perangkat lain:"
echo "# Uji Akses DNS dari VILYA (Harusnya BERHASIL):"
nc -uv 10.66.0.42 53
echo "# Uji Akses DNS dari CLIENT LAIN (misal Durin - Harusnya GAGAL/Timeout):"
nc -uv 10.66.0.42 53
echo "--------------------------------------------------------"

echo "PENTING: Setelah pengujian, jalankan 3 perintah berikut secara berurutan di NARYA untuk menghapus aturan DROP DNS (index mungkin bergeser):"
iptables -D INPUT 5
iptables -D INPUT 5
iptables -D INPUT 6
service bind9 restart

echo -e "\n!!! KONFIGURASI NARYA SELESAI !!!"
#!/bin/bash

# ==============================================================================
# CONFIGURACIÓN AUTOMÁTICA DE RED Y UNIDAD DE RED UPV (Linux)
# ==============================================================================
# Configura:
# 1. WiFi UPVNET (WPA-EAP / PEAP)
# 2. VPN UPV (Cisco VPNC)
# 3. Unidad personal de red (W:) mediante CIFS/SMB en ~/W
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Error: Por favor, ejecuta este script como root (usando sudo)."
  echo "Uso: sudo $0 <usuario_upv> [usuario_local_linux]"
  echo "Ejemplo: sudo $0 tunombre \$USER"
  exit 1
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Uso: sudo $0 <usuario_upv> [usuario_local_linux]"
  exit 1
fi

USUARIO_UPV="$1"
USUARIO_LOCAL="${2:-$SUDO_USER}"

if [ -z "$USUARIO_LOCAL" ] || ! id "$USUARIO_LOCAL" &>/dev/null; then
  echo "Error: No se pudo determinar un usuario local válido. Indícalo como segundo argumento."
  exit 1
fi

# Solicitar contraseña de forma segura (sin mostrarla ni guardarla en el historial)
read -s -p "Introduce tu contraseña de la intranet UPV (${USUARIO_UPV}): " CONTRASENA
echo ""

if [ -z "$CONTRASENA" ]; then
  echo "Error: La contraseña no puede estar vacía."
  exit 1
fi

PRIMERA_LETRA="${USUARIO_UPV:0:1}"
LOCAL_UID=$(id -u "$USUARIO_LOCAL")
LOCAL_GID=$(id -g "$USUARIO_LOCAL")
HOME_LOCAL=$(getent passwd "$USUARIO_LOCAL" | cut -d: -f6)
PUNTO_MONTAJE="${HOME_LOCAL}/W"
UUID_WIFI=$(cat /proc/sys/kernel/random/uuid)
UUID_VPN=$(cat /proc/sys/kernel/random/uuid)

echo ">> Comprobando gestor de paquetes e instalando dependencias..."
if command -v apt-get &> /dev/null; then
  apt-get update
  apt-get install -y network-manager network-manager-vpnc vpnc cifs-utils
elif command -v pacman &> /dev/null; then
  pacman -S --needed --noconfirm networkmanager networkmanager-vpnc vpnc cifs-utils
else
  echo "Error: Gestor de paquetes no soportado (requiere apt-get o pacman)."
  exit 1
fi

echo ">> Configurando WiFi UPVNET..."
cat <<EOF > /etc/NetworkManager/system-connections/UPVNET.nmconnection
[connection]
id=UPVNET
uuid=${UUID_WIFI}
type=wifi
autoconnect=true

[wifi]
ssid=UPVNET
mode=infrastructure

[wifi-security]
key-mgmt=wpa-eap

[802-1x]
eap=peap;
identity=${USUARIO_UPV}@alumno.upv.es
anonymous-identity=
password=${CONTRASENA}
phase2-auth=mschapv2
ca-cert=/etc/ssl/certs/USERTrust_ECC_Certification_Authority.pem
domain-suffix-match=radius.upv.es

[ipv4]
method=auto

[ipv6]
method=auto
EOF

echo ">> Configurando VPN UPV..."
cat <<EOF > /etc/NetworkManager/system-connections/VPN-UPV.nmconnection
[connection]
id=VPN-UPV
uuid=${UUID_VPN}
type=vpn
autoconnect=false
permissions=

[vpn]
service-type=org.freedesktop.NetworkManager.vpnc
IPSec gateway=vpn.upv.es
IPSec ID=soloupv
IPSec secret-flags=0
Xauth username=${USUARIO_UPV}@alumno.upv.es
Xauth password-flags=0
NAT Traversal Mode=natt
IKE DH Group=dh2
Perfect Forward Secrecy=server
Vendor=cisco

[vpn-secrets]
IPSec secret=upvnet
Xauth password=${CONTRASENA}

[ipv4]
method=auto

[ipv6]
method=auto
addr-gen-mode=stable-privacy

[proxy]
EOF

chmod 600 /etc/NetworkManager/system-connections/UPVNET.nmconnection
chmod 600 /etc/NetworkManager/system-connections/VPN-UPV.nmconnection
chown root:root /etc/NetworkManager/system-connections/UPVNET.nmconnection
chown root:root /etc/NetworkManager/system-connections/VPN-UPV.nmconnection
nmcli connection reload

echo ">> Configurando credenciales SMB..."
cat <<EOF > /root/.smbcredentials
username=${USUARIO_UPV}
password=${CONTRASENA}
EOF

chmod 600 /root/.smbcredentials
chown root:root /root/.smbcredentials

echo ">> Preparando punto de montaje en ${PUNTO_MONTAJE}..."
mkdir -p "${PUNTO_MONTAJE}"
chown "${LOCAL_UID}:${LOCAL_GID}" "${PUNTO_MONTAJE}"

if grep -q "${PUNTO_MONTAJE}" /etc/fstab; then
  echo "La entrada para ${PUNTO_MONTAJE} ya existe en /etc/fstab. Omitiendo."
else
  echo "" >> /etc/fstab
  echo "# Montar unidad W para el usuario ${USUARIO_UPV}" >> /etc/fstab
  echo "//nasupv/alumnos/${PRIMERA_LETRA}/${USUARIO_UPV} ${PUNTO_MONTAJE} cifs credentials=/root/.smbcredentials,uid=${LOCAL_UID},gid=${LOCAL_GID},noauto,x-systemd.automount,_netdev,noserverino 0 0" >> /etc/fstab
  systemctl daemon-reload
fi

echo ">> ¡Configuración finalizada con éxito!"

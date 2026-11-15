# 🎓 UPV Linux AutoConfig Network — WiFi, VPN y Unidad W:

Script de automatización en Bash diseñado para **alumnos de la Universitat Politècnica de València (UPV)** que simplifica en un solo comando todo el proceso descrito en el [manual oficial de la Wiki UPV (ManualesVPNparaLinux)](https://wiki.upv.es/confluence/spaces/MANUALES/pages/903381127/Manuales+de+conexi%C3%B3n+VPN+a+la+UPV#Manualesdeconexi%C3%B3nVPNalaUPV-ManualesVPNparaLinux), ampliando además la compatibilidad a sistemas basados en **Arch Linux**.

##  ¿Qué configura este script?

Configurar manualmente los servicios de red de la UPV en Linux requiere instalar dependencias específicas, importar certificados, crear perfiles en NetworkManager y configurar el automontaje CIFS en `/etc/fstab`. Este script realiza todo el proceso de forma automática para cuentas de estudiante (`@alumno.upv.es`):

* **WiFi `UPVNET`:** Configura la autenticación WPA2-Enterprise (PEAP / MSCHAPv2) con el certificado oficial de la entidad certificadora.
* **VPN Corporativa (`VPN-UPV`):** Instala y configura el cliente Cisco VPNC con la pasarela y parámetros oficiales de la UPV.
* **Unidad Personal (`W:`):** Configura el montaje bajo demanda (`systemd.automount`) de tu carpeta del NAS de alumnos directamente en `~/W`.

##  Compatibilidad y Requisitos

* **Arch Linux / Manjaro / EndeavourOS** (`pacman`) — *Probado y en uso diario sin incidencias.*
* **Ubuntu 26.04 / Debian 13 y derivados** (`apt-get`) — *Basado en la guía oficial de la UPV.*
* Sistema con **NetworkManager**, **systemd** y permisos de superusuario (`sudo`).

## 🚀 Instalación y Uso

1. **Clona el repositorio** y accede al directorio:
   ```bash
   git clone [https://github.com/TU_USUARIO/upv-linux-autoconfig.git](https://github.com/TU_USUARIO/upv-linux-autovpnwifi.git)
   cd upv-linux-autovpnwifi

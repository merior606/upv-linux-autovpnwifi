'# UPV Linux AutoConfig Network — WiFi, VPN y Unidad W:

Script de automatización en Bash diseñado para **alumnos de la Universitat Politècnica de València (UPV)** que simplifica en un solo comando todo el proceso descrito en el [manual oficial de la Wiki UPV (ManualesVPNparaLinux)](https://wiki.upv.es/confluence/spaces/MANUALES/pages/903381127/Manuales+de+conexi%C3%B3n+VPN+a+la+UPV#Manualesdeconexi%C3%B3nVPNalaUPV-ManualesVPNparaLinux), ampliando además la compatibilidad a sistemas basados en **Arch Linux**.

## ¿Qué configura este script?

Configurar manualmente los servicios de red de la UPV en Linux requiere instalar dependencias específicas, importar certificados, crear perfiles en NetworkManager y configurar el automontaje CIFS en `/etc/fstab`. Este script realiza todo el proceso de forma automática para cuentas de estudiante (`@alumno.upv.es`):

- **WiFi `UPVNET`:** configura la autenticación WPA2-Enterprise (PEAP / MSCHAPv2) con el certificado oficial de la entidad certificadora.
- **VPN corporativa (`VPN-UPV`):** instala y configura el cliente Cisco VPNC con la pasarela y parámetros oficiales de la UPV. Por defecto usa el grupo `soloupv` y la interfaz de red `tun0` (ver [Configuración por defecto de la VPN](#configuración-por-defecto-de-la-vpn)).
- **Unidad personal (`W:`):** configura el montaje bajo demanda (`systemd.automount`) de tu carpeta del NAS de alumnos directamente en `~/W`.

## Compatibilidad y requisitos

- **Arch Linux / Manjaro / EndeavourOS** (`pacman`) — *probado y en uso diario sin incidencias.*
- **Ubuntu 26.04 / Debian 13 y derivados** (`apt-get`) — *basado en la guía oficial de la UPV.*
- **Máquinas virtuales (VirtualBox, VMware, QEMU/KVM):** funciona sin problemas tanto en modo NAT como en Adaptador Puente (*Bridged*). Aunque una máquina virtual utilice una interfaz Ethernet virtual (y por tanto ignore el perfil WiFi), la **VPN-UPV** y el montaje de la **unidad W:** funcionan exactamente igual que en una instalación nativa.
- Sistema con **NetworkManager**, **systemd** y permisos de superusuario (`sudo`).
- **Microsoft Authenticator** en el móvil, configurado previamente para la VPN de la UPV (ver [Autenticación multifactor (MFA)](#autenticación-multifactor-mfa-en-la-vpn)).

## Instalación y uso

1. **Clona el repositorio** y accede al directorio:

   ```bash
   git clone https://github.com/merior606/upv-linux-autovpnwifi.git
   cd upv-linux-autovpnwifi
   ```

2. **Dale permisos de ejecución** al script:

   ```bash
   chmod +x setup-upv.sh
   ```

3. **Ejecútalo** pasando como argumento tu identificador de usuario de la intranet UPV (la parte anterior a `@alumno.upv.es`):

   ```bash
   sudo ./setup-upv.sh <usuario_upv> [usuario_local_linux]
   ```

4. **Reinicia el equipo** cuando el script termine:

   ```bash
   sudo reboot
   ```

> [!IMPORTANT]
> Es **necesario reiniciar el equipo tras ejecutar el script** para que todo (WiFi, VPN y unidad `W:`) aparezca y funcione correctamente.

> [!TIP]
> ¿Te has equivocado con el usuario o la contraseña? No pasa nada: puedes volver a ejecutar el script y se sobrescribirá la configuración anterior (ver [Problemas conocidos](#problemas-conocidos)).

### 📝 Ejemplo práctico

Supongamos que un alumno llamado Alejandro García Pedrosa tiene el correo `agarped@alumno.upv.es` y su usuario en Linux es `alejandro`:

```bash
sudo ./setup-upv.sh agarped
```

**¿Qué ocurrirá paso a paso?**

1. El script detectará automáticamente que el usuario local es `alejandro` (gracias a `$SUDO_USER`, aunque también puedes especificarlo manualmente con `sudo ./setup-upv.sh agarped alejandro`).
2. Te pedirá tu contraseña de la intranet en pantalla sin mostrar los caracteres al escribir:

   ```text
   Introduce tu contraseña de la intranet UPV (agarped):
   ```

3. Instalará los paquetes necesarios (`network-manager-vpnc`, `vpnc`, `cifs-utils`) según tu distribución.
4. Creará los perfiles `UPVNET` y `VPN-UPV` en NetworkManager y configurará el punto de montaje `/home/alejandro/W`.
5. Al terminar, tendrás que reiniciar el equipo para que todo quede funcionando.

## Cómo conectarse tras la instalación

- **WiFi:** se conectará automáticamente al detectar la red `UPVNET` en el campus.
- **VPN:** actívala desde el icono de red de tu escritorio seleccionando `VPN-UPV` o desde la terminal:

  ```bash
  nmcli connection up VPN-UPV
  ```

  Tras intentar conectarte, tendrás que **autorizar el acceso desde el móvil con Microsoft Authenticator** (ver sección siguiente).

- **Unidad W:** una vez conectado a `UPVNET` o a `VPN-UPV`, entra en la carpeta `~/W` desde tu explorador de archivos o terminal; systemd la montará automáticamente al acceder.

## Autenticación multifactor (MFA) en la VPN

La VPN de la UPV exige verificación en dos pasos. Cada vez que intentes conectarte a `VPN-UPV`, recibirás una solicitud en tu móvil que debes **aprobar desde Microsoft Authenticator**; hasta que no la autorices, la conexión no se completará.

> [!IMPORTANT]
> Microsoft Authenticator debe estar **configurado previamente** siguiendo la guía oficial de la UPV: [Configurar la autenticación Multi-Factor (MFA o 2FA) en VPN, Microsoft 365, Teams…](https://wiki.upv.es/confluence/spaces/MANUALES/pages/677052483/Configurar+la+autenticacio%CC%81n+Multi-Factor+MFA+o+2FA+en+VPN+Microsoft+365+teams). Sin este paso no podrás conectarte a la VPN.

## Configuración por defecto de la VPN

El perfil `VPN-UPV` se crea con estos valores por defecto:

| Parámetro | Valor por defecto |
|---|---|
| **Grupo** | `soloupv` |
| **Interfaz de red** | `tun0` |

El grupo `soloupv` permite acceder a todos los recursos de la Intranet de la UPV, pero el tráfico de navegación por Internet **no pasa por la UPV**. Es la opción que la propia UPV recomienda por defecto en su [manual de VPN para Linux](https://wiki.upv.es/confluence/spaces/MANUALES/pages/903381134/Linux+-+VPN+con+versiones+anteriores+de+Ubuntu).

## Problemas conocidos

> [!WARNING]
> **No actives la VPN-UPV estando conectado a la red de la UPV dentro del campus.** Si lo haces, pueden aparecer errores de conexión. Dentro del campus (`UPVNET`) no es necesaria la VPN: la unidad `W:` y el resto de recursos son accesibles directamente. Usa la VPN solo cuando estés fuera de la red de la UPV.

> [!NOTE]
> Si tras ejecutar el script la WiFi, la VPN o la unidad `W:` no aparecen o no funcionan, comprueba primero que has **reiniciado el equipo**.

### Me equivoqué con el usuario o la contraseña

Si introdujiste mal tu usuario de la intranet o tu contraseña, **vuelve a ejecutar el script** con los datos correctos:

```bash
sudo ./setup-upv.sh <usuario_upv> [usuario_local_linux]
```

La configuración anterior se **sobrescribirá** con la nueva, así que no hace falta borrar nada a mano. Recuerda reiniciar el equipo después.

## Seguridad y privacidad de tus datos

Tratándose de credenciales universitarias, el script está diseñado para garantizar que tus datos nunca queden expuestos:

- **100% transparente y auditable:** es un único archivo de texto plano en Bash sin binarios ocultos ni dependencias externas. Puedes leer cada línea antes de ejecutarlo.
- **Cero conexiones externas:** el script no envía telemetría ni transmite tus datos a ningún servidor de terceros; únicamente escribe los archivos de configuración estándar de tu propio sistema operativo.
- **Sin rastro en el historial de comandos:** al solicitar la contraseña de forma interactiva con `read -s` en lugar de pasarla como parámetro, tu clave nunca se guarda en `~/.bash_history` ni es visible en la lista de procesos del sistema (`ps`).
- **Permisos estrictos (`chmod 600`):** tanto los perfiles de NetworkManager (`/etc/NetworkManager/system-connections/`) como el fichero de credenciales de red (`/root/.smbcredentials`) pertenecen exclusivamente a `root:root` con permisos `600`, impidiendo que otros usuarios o aplicaciones sin privilegios puedan leerlos.

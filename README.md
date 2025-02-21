# Dockerized Kali Linux Attack Box (With Desktop)
I use TryHackMe and Hack The Box as learning resources and often need an "attack box" with penetration testing tools, typically Kali Linux. With spare resources on my free Oracle VPS, I set up my own attack box for on-demand access. This setup supports TryHackMe, Hack The Box, and other testing environments, whether cloud-based or in my homelab. It also, importantly, works fine with VPNs which can sometimes be an issue due to docker networking. I deployed a Kali container with a desktop interface on Docker and secured access via RDP tunneled over SSH.

![Kali SSH Tunnel](/images/Kali%20SSH%20Tunnel.jpg)
## Setting Up the Docker Container
I'm using Docker to run my Kali attack box as a lightweight container on my VPS. Below are the Dockerfile and Docker Compose configurations:

**Dockerfile:**
```
FROM kalilinux/kali-rolling:arm64

ENV DEBIAN_FRONTEND noninteractive

RUN apt update
RUN apt install -y kali-linux-large xrdp xorg x11-xserver-utils
RUN apt install -y kali-desktop-xfce
RUN apt install -y vim inetutils-ping

RUN echo "exec startxfce4" > /root/.xinitrc

RUN systemctl enable xrdp

RUN echo "root:toor" | chpasswd
```
This file sets up a Kali Linux container using the ARM64 image (matching my VPS's architecture). It installs the  `kali-linux-large` pen testing suite (this is a large package it may take a while, feel free to install whatever fits you're needs from [Kali's Metapackages](https://www.kali.org/docs/general-use/metapackages/) ), the XFCE desktop, and `xrdp` for remote access. Change the password after login.

**docker compose file:**
```
services:
  kali:
    build: .
    container_name: kali
    user: root
    privileged: true
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
    ports:
      - "127.0.0.1:3389:3389"
    volumes:
      - kali_home:/root
    command: >
      /bin/bash -c "
      service xrdp start &&
      startxfce4
      "
volumes:
	kali_home:
```
This file builds and runs the container, granting necessary privileges for networking tools, mounting a persistent data volume, and exposing RDP on localhost (`127.0.0.1:3389`). The startup command ensures `xrdp` and the desktop environment (`xfce`) are running for GUI access.
## Running the Container (and Connecting)
To run the Kali container, use `docker-compose` to build and start it. Navigate to the directory containing your `docker-compose.yml` and `dockefile`.
```
sudo docker compose up -d --build
```
I connect to the Docker container via RDP, but to enhance security, I tunnel the RDP connection over SSH instead of exposing the RDP port. Ensure your SSH is set up correctly. 

To connect, set up an SSH tunnel and RDP to `localhost:3389`.
### From a Linux Machine:
I use [Remmina](https://remmina.org/) to create an RDP connection with an SSH tunnel. In the `Basic` tab, set the destination to `localhost:3389`. In the `SSH Tunnel` tab, configure the SSH connection (e.g., `USER@SERVER_PUBLIC_IP:PORT`). Configure the authentication by specifying the private key to use. 

![Kali AB Remmina](/images/Kali-AB-Remmina.jpg)

### From a Windows Machine:
On Windows, I create the SSH tunnel using PowerShell and connect via Remote Desktop (`mstsc.exe`) to `localhost`. The SSH command is:

```
ssh -L 3389:localhost:3389 user@VPS_PUBLIC_IP -p SSH_PORT_NUMBER  -i PATH/TO/SSH/PRIVATE/KEY -N
```

Replace the placeholders with your server's public IP, SSH port, and private key path. The `-N` option suppresses output, but after running this, connecting to `localhost` via `mstsc.exe` succeeds and opens the Kali login screen.

![Kali RDP From Windows](/images/Kali-RDP-Windows.jpg)

This setup also works for macOS with any RDP client.

**Note:** The `verification code:` prompt is due to MFA on my SSH setup. It may prompt for a password if needed, or not at all if your SSH key isn't password-protected.
## Quick Test 
The Kali container functions like a regular Kali machine, with full VPN support. Here, I connect to TryHackMe via OpenVPN, confirming my VPN IP (`10.6.4.161`). I then run an Nmap scan against the target machine's private IP (`10.10.243.23`).

![Kali Container Showcase](/images/Kali-Container-Showcase.jpeg)

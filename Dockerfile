FROM kalilinux/kali-rolling:arm64

ENV DEBIAN_FRONTEND noninteractive

RUN apt update
RUN apt install -y kali-linux-large xrdp xorg x11-xserver-utils
RUN apt install -y kali-desktop-xfce
RUN apt install -y vim inetutils-ping

RUN echo "exec startxfce4" > /root/.xinitrc

RUN systemctl enable xrdp

RUN echo "root:toor" | chpasswd
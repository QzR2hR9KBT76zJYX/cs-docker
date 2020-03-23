FROM debian:buster-slim

LABEL maintainer="none@gmail.com"
ARG PUID=1000

ENV STEAMCMDDIR /home/steam/steamcmd
ENV STEAMAPPEXE /home/steam/hlds
ENV STEAMAPPDIR /home/steam/hlds/cstrike

# Install, update & upgrade packages
# Create user for the server
# This also creates the home directory we later need
# Clean TMP, apt-get cache and other stuff to make the image smaller
# Create Directory for SteamCMD
# Download SteamCMD
# Extract and delete archive
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		lib32stdc++6=8.3.0-6 \
		lib32gcc1=1:8.3.0-6 \
		wget=1.20.1-1.1 \
		ca-certificates=20190110 \
	&& useradd -u $PUID -m steam \
	&& su steam -c \
		"mkdir -p ${STEAMCMDDIR} \
		&& wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar -C ${STEAMCMDDIR} -zxvf -"

COPY config/hlds.install ${STEAMCMDDIR}
# COPY config/steamapps ${STEAMAPPEXE}/steamapps

RUN	su steam -c \
		"${STEAMCMDDIR}/steamcmd.sh +runscript hlds.install \
	&& mkdir -p ${STEAMAPPDIR}/addons/metamod/dlls \
    && mkdir -p ${STEAMAPPDIR}/addons/dproto \
    && wget -qO- 'http://prdownloads.sourceforge.net/metamod/metamod-$metamod_version-linux.tar.gz?download' | tar -C ${STEAMAPPDIR}/addons/metamod/dlls -zxvf - \
    && wget -qO- 'http://www.amxmodx.org/release/amxmodx-$amxmod_version-base-linux.tar.gz' | tar -C ${STEAMAPPDIR} -zxvf - \
    && wget -qO- 'http://www.amxmodx.org/release/amxmodx-$amxmod_version-cstrike-linux.tar.gz' | tar -C ${STEAMAPPDIR} -zxvf -" \
	&& apt-get remove --purge -y \
	   wget \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

COPY config/cstrike ${STEAMAPPDIR}

# Switch to user steam
USER steam

WORKDIR $STEAMAPPEXE

VOLUME $STEAMAPPEXE

ENTRYPOINT ${STEAMAPPEXE}/hlds_run \
			-game cstrike +maxplayers 20 +map cs_mansion

EXPOSE 27015/tcp 27015/udp
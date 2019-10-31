FROM rubensa/ubuntu-systemd-user
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Add systemd unit to fix DOCKER_GROUP_ID
ADD fix-docker.service /etc/systemd/system/fix-docker.service
ADD fix-docker.sh /usr/sbin/fix-docker.sh

# Add systemd unit to fix SOFTWARE_GROUP_ID
ADD fix-software.service /etc/systemd/system/fix-software.service
ADD fix-software.sh /usr/sbin/fix-software.sh

# Docker group support
ARG DOCKER_IN_DOCKER_SUPPORT
ARG DOCKER_GROUP_ID=1001
ENV DOCKER_GROUP_ID=$DOCKER_GROUP_ID
ARG DOCKER_GROUP=docker
ENV DOCKER_GROUP=$DOCKER_GROUP

# Define software group id's
ARG SOFTWARE_GROUP_ID=2000
ENV SOFTWARE_GROUP_ID=${SOFTWARE_GROUP_ID}

# Define software group and installation folder
ARG SOFTWARE_GROUP=software 
ENV SOFTWARE_GROUP=${SOFTWARE_GROUP}
ARG SOFTWARE_INSTALL_DIR=/software
ENV SOFTWARE_INSTALL_DIR=${SOFTWARE_INSTALL_DIR}

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Install software and needed libraries
    && apt-get -y install acl libglib2.0-bin pulseaudio-utils cups-client x11-utils \
    #
    # Docker group support
    && if [ "$DOCKER_IN_DOCKER_SUPPORT" = "true" ] ; \
      then addgroup --gid ${DOCKER_GROUP_ID} ${DOCKER_GROUP}; usermod -a -G ${DOCKER_GROUP} ${USER}; \
    fi \
    #
    # Create a software group
    && addgroup --gid ${SOFTWARE_GROUP_ID} ${SOFTWARE_GROUP} \
    #
    # Assign software group to non-root user
    && usermod -a -G ${SOFTWARE_GROUP} ${USER} \
    #
    # Assign audio group to non-root user
    && usermod -a -G audio ${USER} \
    #
    # Assign video group to non-root user
    && usermod -a -G video ${USER} \
    #
    # Create software installation directory
    && mkdir -p ${SOFTWARE_INSTALL_DIR} \
    #
    # Assign software group folder ownership
    && chgrp -R ${SOFTWARE_GROUP} ${SOFTWARE_INSTALL_DIR} \
    #
    # Give write acces to the group
    && chmod -R g+wX ${SOFTWARE_INSTALL_DIR} \
    #
    # Set ACL to files created in the folder
    && setfacl -d -m u::rwX,g::rwX,o::r-X ${SOFTWARE_INSTALL_DIR} \
    #
    # Remove systemd tmp files services so we can share host X11 temp files
    && rm -f /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup.service \
    #
    # Disable dbus service as we are going to use host service
    && rm -f /lib/systemd/system/sockets.target.wants/dbus.socket \
    && systemctl mask dbus.service \
    #
    # Enable systemd unit to fix SOFTWARE_GROUP_ID
    && chmod +x /usr/sbin/fix-software.sh \
    && systemctl enable fix-software.service \
    #
    # Enable systemd unit to fix DOCKER_GROUP_ID
    && if [ "$DOCKER_IN_DOCKER_SUPPORT" = "true" ] ; \
      then chmod +x /usr/sbin/fix-docker.sh ; systemctl enable fix-docker.service; \
    fi \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

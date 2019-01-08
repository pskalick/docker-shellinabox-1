#!/bin/bash

set -e

hex()
{
	openssl rand -hex 8
}

echo "Preparing container .."
COMMAND="/usr/bin/shellinaboxd --debug --no-beep --disable-peer-check -u shellinabox -g shellinabox -c /var/lib/shellinabox -p ${SIAB_PORT} --user-css ${SIAB_USERCSS}"

if [ "$SIAB_PKGS" != "none" ]; then
	set +e
	/usr/bin/apt-get update
	/usr/bin/apt-get install -y $SIAB_PKGS
	/usr/bin/apt-get clean
	/bin/rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	set -e
fi

if [ "$SIAB_SSL" != "true" ]; then
	COMMAND+=" -t"
fi

if [ "${SIAB_ADDUSER}" == "true" ]; then
	sudo=""
	if [ "${SIAB_SUDO}" == "true" ]; then
		sudo="-G sudo"
	fi
	if [ -z "$(getent group ${SIAB_GROUP})" ]; then
		/usr/sbin/groupadd -g ${SIAB_GROUPID} ${SIAB_GROUP}
	fi
	if [ -z "$(getent passwd ${SIAB_USER})" ]; then
		/usr/sbin/useradd -u ${SIAB_USERID} -g ${SIAB_GROUPID} -s ${SIAB_SHELL} -d ${SIAB_HOME} -m ${sudo} ${SIAB_USER}
		if [ "${SIAB_PASSWORD}" == "putsafepasswordhere" ]; then
			SIAB_PASSWORD=$(hex)
			echo "Autogenerated password for user ${SIAB_USER}: ${SIAB_PASSWORD}"
		fi
		echo "${SIAB_USER}:${SIAB_PASSWORD}" | /usr/sbin/chpasswd
		unset SIAB_PASSWORD
	fi
fi

for service in ${SIAB_SERVICE}; do
	COMMAND+=" -s ${service}"
done

if [ "$SIAB_SCRIPT" != "none" ]; then
	set +e
	/usr/bin/curl -s -k ${SIAB_SCRIPT} > /prep.sh
	chmod +x /prep.sh
	echo "Running ${SIAB_SCRIPT} .."
	/prep.sh
	set -e
fi

echo "Starting container .."
if [ "$@" = "shellinabox" ]; then
	echo "Executing: ${COMMAND}"
	exec ${COMMAND}
else
	echo "Not executing: ${COMMAND}"
	echo "Executing: ${@}"
	exec $@
fi

useradd testik
echo testik | passwd testik --stdin

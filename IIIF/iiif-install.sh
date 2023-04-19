#!/bin/bash

# 
# check if the script is run as root
root_checking () {
	if [ ! $( id -u ) -eq 0 ]; then
		echo "To perform this action you must be logged in with root rights"
		exit 1;
	fi
}

# check if command exists
command_exists () {
	type "$1" &> /dev/null;
}

install_curl () {
	if command_exists apt-get; then
		apt-get -y update
		apt-get -y -q install curl
	fi

	if ! command_exists curl; then
		echo "=== command curl not found ==="
		exit 1;
	fi
}

# install apache2
install_apache2 () {
    # 1. update package list
    apt-get -y update
    # 2. install apache2
    apt-get -y -q install apache2 libapache2-mod-fcgid

    if ! command_exists apache2; then
        echo "=== command apache2 not found ==="
        exit 1;
    elif command_exists apache2; then
        echo "=== apache2 installed ==="
        # 3. start web server
        systemctl start apache2
    fi
}

# install iipserver
install_iipserver () {
    # 1. install iipimage-server
    apt-get -y install iipimage-server
    # 2. Change image server's data directory
    echo "=== Configuring IIPImage Server ==="
    cp -r /usr/lib/iipimage-server/ /var/www/iipimage-server/
    filename="/etc/apache2/mods-available/iipsrv.conf";
    search='ScriptAlias /iipsrv/ "/usr/lib/iipimage-server/"';
    replace='ScriptAlias /iiif "/var/www/iipimage-server/iipsrv.fcgi"';
    sed -i "s|$search|$replace|" $filename
    sed -i 's|FcgidInitialEnv MEMCACHED_SERVERS "localhost"|FcgidInitialEnv MEMCACHED_SERVERS "localhost"\nFcgidInitialEnv URI_MAP "iiif=>IIIF"|' $filename

    # 3. Enable the necessary Apache modules
    echo "=== Enabling the necessary Apache modules ==="
    a2enmod headers
    systemctl restart apache2
    a2enmod iipsrv
    systemctl restart apache2
    # 4. Enable CORS
    echo "=== Enabling CORS ==="
    echo "Header set Access-Control-Allow-Origin *" >> /etc/apache2/apache2.conf
}
IP=$(hostname -I | awk '{print $1}');

root_checking

if ! command_exists curl ; then
    echo "command curl not found. Installing..."
	install_curl;
fi

if [ -f /etc/debian_version ] ; then
    # Web server setup
    echo "=== Installing apache2 ==="
    install_apache2
    # 4. check if apache2 is up
    echo "=== Checking if apache2 is up. IP: $IP ==="
    if curl -I "$IP" 2>&1 | grep -w "200\|301" ; then
        echo "=== apache2 is up ==="
    else
        echo "=== apache2 is down ==="
    fi

    # Install the IIPImage Server
    echo "=== Installing IIPImage Server ==="
    install_iipserver
    echo "=== Checking if IIPImage Server is up. IP: $IP ==="
    # 5. check if IIPImage Server is up
    if curl -I "$IP/iiif" 2>&1 | grep -w "400\|301" ; then
        echo "=== IIPImage Server is up ==="
    else
        echo "=== IIPImage Server is down ==="
    fi
    echo "=== Installation completed ===";
else
    echo "Not supported OS";
    exit 1;
fi
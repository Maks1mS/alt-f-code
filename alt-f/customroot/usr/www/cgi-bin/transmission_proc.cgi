#!/bin/sh

. common.sh
check_cookie
read_args

CONFF=/var/lib/transmission
JSON=settings.json
SMBCONF=/etc/samba/smb.conf

TRANSMISSION_USER=transmission
TRANSMISSION_GROUP=BT

#debug
# this is to disappear after RC3 (included in common.sh)
# -----------------------------------------------------
check_folder() {
	if ! test -d "$1"; then
		echo "\"$1\" does not exists or is not a folder."
		return 1
	fi

	tmp=$(readlink -f "$1")
	while ! mountpoint -q "$tmp"; do
		tmp=$(dirname "$tmp")
	done

	if test "$tmp" = "/" -o "$tmp" = "."; then
		echo "\"$1\" is not on a filesystem."
		return 1
	fi

	if test "$tmp" = "$1"; then
		echo "\"$1\" is a filesystem root, not a folder."
		return 1
	fi
}
# ----------------------------------------

if test -n "$WebPage"; then
	if ! rctransmission status >& /dev/null; then
		rctransmission start  >& /dev/null
	fi
	
	rpc_port=$(sed -n 's/.*"rpc-port":[[:space:]]*\([[:digit:]]*\).*/\1/p' $CONFF/$JSON)
	embed_page "http://${HTTP_HOST%%:*}:${rpc_port}" "Transmission Page"

elif test -n "$Submit"; then

	if test -n "$WATCH_DIR"; then
		WATCH_DIR=$(httpd -d "$WATCH_DIR")
	fi

	if test "$(basename $WATCH_DIR)" = "Public"; then
		msg "You must create a folder for Transmission." 
	elif ! res=$(check_folder "$WATCH_DIR"); then
		msg "$res"
	fi

	INCOMPLETE_DIR="$WATCH_DIR/InProgress"
	DOWNLOAD_DIR="$WATCH_DIR/Finished"

	if ! test -d "$DOWNLOAD_DIR" -a -d "$WATCH_DIR" -a -d "$INCOMPLETE_DIR"; then
		mkdir -p "$DOWNLOAD_DIR" "$WATCH_DIR" "$INCOMPLETE_DIR"
	fi

	chown -R $TRANSMISSION_USER:$TRANSMISSION_GROUP "$WATCH_DIR"
	chmod -R g+rws "$WATCH_DIR"

	# escape sed special char '&' and '|' delimiter on pathnames
	EWATCH_DIR=$(echo "$WATCH_DIR" | sed 's|\([]\&\|[]\)|\\\1|g')
	EDOWNLOAD_DIR=$(echo "$DOWNLOAD_DIR" | sed 's|\([]\&\|[]\)|\\\1|g')
	EINCOMPLETE_DIR=$(echo "$INCOMPLETE_DIR" | sed 's|\([]\&\|[]\)|\\\1|g')

	sed -i -e 's|.*"download-dir":.*|    "download-dir": "'"$EDOWNLOAD_DIR"'",|' \
	-e 's|.*"incomplete-dir":.*|    "incomplete-dir": "'"$EINCOMPLETE_DIR"'",|' \
	-e 's|.*"watch-dir":.*|    "watch-dir": "'"$EWATCH_DIR"'",|' \
	"$CONFF/$JSON"

	chown $TRANSMISSION_USER:$TRANSMISSION_GROUP "$CONFF/$JSON"

	if ! grep -q "^\[Transmission\]" $SMBCONF; then
		cat<<EOF >> $SMBCONF

[Transmission]
	comment = Transmission Download area
	path = $WATCH_DIR
	valid users = +BT
	read only = no
	available = yes
EOF

	else
		sed -i "/\[Transmission\]/,/\[.*\]/ { s|path.*|path = $WATCH_DIR|}" $SMBCONF
	fi

	if rcsmb status >& /dev/null; then
		rcsmb reload >& /dev/null
	fi

	if rctransmission status >& /dev/null; then
		rctransmission reload >& /dev/null
	fi

	#enddebug
	gotopage /cgi-bin/user_services.cgi
fi

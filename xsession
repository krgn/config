#!/bin/sh

eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK 

source $HOME/.profile

exec urxvtd -f &
exec conky &
exec trayerman.sh &
exec xsetroot -solid black &
exec xscreensaver &

exec dbus-launch --sh-syntax --exit-with-session $HOME/.cabal/bin/xmonad

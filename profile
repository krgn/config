#!/bin/sh

function join() {
    local IFS=$1
    shift
    echo "$*"
}

SSH_AUTH_SOCK=`ss -xl | grep -o "/run/user/$(id -u)/keyring-.*/ssh"`
[ -z "$SSH_AUTH_SOCK" ] || export SSH_AUTH_SOCK

GPG_AGENT_INFO=`ss -xl | grep -o "/run/user/$(id -u)/keyring-.*/gpg"`
[ -z "$GPG_AGENT_INFO" ] || export GPG_AGENT_INFO

export EDITOR=vim
export ANDROID_HOME=$HOME/src/android/sdk/sdk
export BROWSER=chromium-browser
export CLASSPATH=$CLASSPATH:$HOME/bin/eclipse/plugins:/usr/lib/jvm/java-7-openjdk:/usr/share/java:$(join ":" $ANDROID_HOME/platforms/*)
export PATH=$HOME/.cabal/bin:$HOME/.node_modules/bin:$HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:/usr/bin/vendor_perl:/usr/bin/site_perl/:$HOME/.gem/ruby/1.9.1/bin:$PATH
export VST_PATH=$HOME/lib/vst
export LD_LIBRARY_PATH=$ANDROID_HOME/tools/lib/:$LD_LIBRARY_PATH
export GEM_PATH=$HOME/.gem/ruby/1.9.1:/usr/lib/ruby/gems/1.9.1/ 
export GEM_HOME=$HOME/.gem/ruby/1.9.1
export MAILDIR=$HOME/mail


#! /bin/sh

# Run only when the interface is not "lo":
if [ $1 = "lo" ]; then
   exit 0
fi

# Run whenever an interface gets "up", not otherwise:
if [ $2 != "up" ]; then
   exit 0
fi

# Get LANG
. /etc/default/locale
export LANG

# Initialize gettext support
. gettext.sh
TEXTDOMAIN="tails"
export TEXTDOMAIN

tor_has_bootstrapped() {
   sudo -n -u debian-tor /usr/local/sbin/tor-has-bootstrapped
}

while ! tor_has_bootstrapped; do
   sleep 10
done

# We now know that whatever Tor settings we are using works, so if Tor
# Launcher is still running, we can just kill it and make sure it
# won't start next network reconnect. A reason for this happening is
# if Tor was restarted by tordate, e.g. if the clock was to incorrect.
if pgrep -f "firefox --app.*tor-launcher-standalone"; then
   pkill -f "firefox --app.*tor-launcher-standalone"
   pref=/user/Data/Browser/profile.default/prefs.js
   sed -i '/^user_pref("extensions\.torlauncher\.prompt_at_startup"/d' "${pref}"
   echo 'user_pref("extensions.torlauncher.prompt_at_startup", false);' >> "${pref}"
fi

/usr/local/sbin/tails-notify-user \
   "`gettext \"Tor is ready\"`" \
   "`gettext \"You can now access the Internet.\"`"

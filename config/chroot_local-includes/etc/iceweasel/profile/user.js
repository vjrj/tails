// Override prefs set in 000-tor-browser.js
user_pref("extensions.enabledScopes", 15);
user_pref("network.security.ports.banned", "8118,8123,9050,9051,9061,9062,9151");

// Adblock Plus preferences (Tails-specific, as TBB does not ship this extension)
user_pref("extensions.adblockplus.correctTypos", false);
user_pref("extensions.adblockplus.currentVersion", "2.1");
user_pref("extensions.adblockplus.savestats", false);
user_pref("extensions.adblockplus.showinaddonbar", false);
user_pref("extensions.adblockplus.showintoolbar", false);
user_pref("extensions.adblockplus.subscriptions_autoupdate", false);

// HTTPS Everywhere preferences
// We use the same value as the TBB unless noted.
user_pref("extensions.https_everywhere._observatory.popup_shown", true);
user_pref("extensions.https_everywhere.toolbar_hint_shown", true); // Tails-specific

// Block read and write access to the history in non-Tor mode
user_pref("extensions.torbutton.block_nthread", true);
user_pref("extensions.torbutton.block_nthwrite", true);

// Torbutton preferences the TBB also sets.
// We use the same value as the TBB unless noted.
user_pref("extensions.torbutton.fresh_install", false);
user_pref("extensions.torbutton.tor_enabled", true);
user_pref("extensions.torbutton.proxies_applied", true);
user_pref("extensions.torbutton.settings_applied", true);
user_pref("extensions.torbutton.socks_host", "127.0.0.1");
user_pref("extensions.torbutton.socks_port", 9151); // Tails-specific
user_pref("extensions.torbutton.tz_string", "UTC+00:00");

// .saved version of the Torbutton preferences the TBB also sets
user_pref("extensions.torbutton.saved.fresh_install", false);
user_pref("extensions.torbutton.saved.tor_enabled", true);
user_pref("extensions.torbutton.saved.proxies_applied", true);
user_pref("extensions.torbutton.saved.settings_applied", true);
user_pref("extensions.torbutton.saved.socks_host", "127.0.0.1");
user_pref("extensions.torbutton.saved.socks_port", 9151);

// Tails -specific Torbutton preferences
user_pref("extensions.torbutton.block_tforms", false);
user_pref("extensions.torbutton.disable_domstorage", false);
user_pref("extensions.torbutton.display_panel", false);
user_pref("extensions.torbutton.launch_warning", false);
user_pref("extensions.torbutton.lastUpdateCheck", "9999999999.999");
user_pref("extensions.torbutton.no_updates", true);
user_pref("extensions.torbutton.nonontor_sessionstore", true);
user_pref("extensions.torbutton.nontor_memory_jar", true);
user_pref("extensions.torbutton.prompted_language", true);
user_pref("extensions.torbutton.socks_remote_dns", true);
user_pref("extensions.torbutton.socks_version", 5);
user_pref("extensions.torbutton.startup", true);
user_pref("extensions.torbutton.startup_state", 1);
user_pref("extensions.torbutton.test_enabled", false); // Tails-specific
user_pref("extensions.torbutton.tor_memory_jar", true);
user_pref("extensions.torbutton.updateNeeded", false);
user_pref("extensions.torbutton.use_privoxy", false);
user_pref("extensions.torbutton.versioncheck_enabled", true);
user_pref("extensions.torbutton.warned_ff3", true);

// .saved version of the Tails -specific Torbutton preferences
user_pref("extensions.torbutton.saved.socks_remote_dns", true);
user_pref("extensions.torbutton.saved.socks_version", 5);
user_pref("extensions.torbutton.saved.type", 1);

// These must be set to the same value to prevent Torbutton from
// flashing its upgrade notification.
user_pref("extensions.torbutton.lastBrowserVersion", "Tails");
user_pref("torbrowser.version", "Tails");

// Proxy and proxy security
user_pref("network.proxy.socks_port", 9151);

// NoScript preferences the TBB also sets.
// We use the same value as the TBB unless noted.
user_pref("capability.policy.maonoscript.javascript.enabled", "allAccess");
user_pref("capability.policy.maonoscript.sites", "addons.mozilla.org about: about:addons about:blank about:blocked about:certerror about:config about:crashes about:credits about:home about:neterror about:plugins about:privatebrowsing about:sessionrestore chrome: resource:");
user_pref("noscript.ABE.enabled", false);
user_pref("noscript.ABE.notify", false);
user_pref("noscript.ABE.wanIpAsLocal", false);
user_pref("noscript.autoReload", false);
user_pref("noscript.confirmUnblock", false);
user_pref("noscript.contentBlocker", true);
user_pref("noscript.default", "about:blank about:credits addons.mozilla.org flashgot.net google.com gstatic.com googlesyndication.com informaction.com yahoo.com yimg.com maone.net noscript.net hotmail.com msn.com passport.com passport.net passportimages.com live.com");
user_pref("noscript.firstRunRedirection", false);
user_pref("noscript.global", true);
user_pref("noscript.gtemp", "");
user_pref("noscript.opacizeObject", 3);
user_pref("noscript.forbidWebGL", true);
user_pref("noscript.forbidFonts", false);
user_pref("noscript.options.tabSelectedIndexes", "5,0,0");
user_pref("noscript.policynames", "");
user_pref("noscript.secureCookies", true);
user_pref("noscript.showAllowPage", false);
user_pref("noscript.showBaseDomain", false);
user_pref("noscript.showDistrust", false);
user_pref("noscript.showRecentlyBlocked", false);
user_pref("noscript.showTemp", false);
user_pref("noscript.showTempToPerm", false);
user_pref("noscript.showUntrusted", false);
user_pref("noscript.STS.enabled", false);
user_pref("noscript.subscription.lastCheck", -142148139);
user_pref("noscript.temp", "");
user_pref("noscript.untrusted", "google-analytics.com"); // Tails-specific
user_pref("noscript.forbidMedia", false);
// Quoting TBB: "Now handled by plugins.click_to_play"
// Tails: we don't support these plugins, so letting NoScript block it seems
// to be potentially useful defense-in-depth.
// user_pref("noscript.forbidFlash", false);
// user_pref("noscript.forbidSilverlight", false);
// user_pref("noscript.forbidJava", false);
// user_pref("noscript.forbidPlugins", false);
// Usability tweaks
user_pref("noscript.showPermanent", false);
user_pref("noscript.showTempAllowPage", true);
user_pref("noscript.showRevokeTemp", true);
user_pref("noscript.notify", false);

// Other non-Torbutton, Tails-specific prefs
user_pref("browser.download.manager.closeWhenDone", true);
user_pref("extensions.foxyproxy.last-version", "99999.99");
user_pref("extensions.foxyproxy.socks_remote_dns", true);
user_pref("extensions.update.enabled", false);
user_pref("layout.spellcheckDefault", 0);
user_pref("media.peerconnection.enabled", false);
user_pref("network.dns.disableIPv6", true);
user_pref("security.warn_submit_insecure", true);

/* T430 slstatus saved configuration. */
const unsigned int interval = 1000;
static const char unknown_str[] = "n/a";
#define MAXLEN 2048

static const struct arg args[] = {
	{ battery_perc, "BAT %s%% | ", "BAT0" },
	{ datetime,     "%s",         "%a %d %b %H:%M" },
};

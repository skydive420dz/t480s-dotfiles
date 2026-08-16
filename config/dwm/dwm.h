/* T430 dwm saved configuration, with intentional T480s app substitutions. */
#include <X11/XF86keysym.h>

static const unsigned int borderpx = 1;
static const unsigned int snap = 32;
static const int showbar = 1;
static const int topbar = 1;
static const char *fonts[] = { "Iosevka Aile:size=10" };
static const char dmenufont[] = "Iosevka Aile:size=10";
static const char col_gray1[] = "#222222";
static const char col_gray2[] = "#444444";
static const char col_gray3[] = "#bbbbbb";
static const char col_gray4[] = "#eeeeee";
static const char col_cyan[] = "#005577";
static const char *colors[][3] = {
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel] = { col_gray4, col_cyan, col_cyan },
};

static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	{ NULL, NULL, NULL, 0, 0, -1 },
};

static const float mfact = 0.55;
static const int nmaster = 1;
static const int resizehints = 0;
static const int lockfullscreen = 1;
static const int refreshrate = 120;

static const Layout layouts[] = {
	{ "[]=", tile },
	{ "><>", NULL },
	{ "[M]", monocle },
};

#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY, view,       {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY, toggleview, {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY, tag,        {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY, toggletag,  {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

static char dmenumon[2] = "0";
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[] = { "ghostty", NULL };
static const char *emacscmd[] = { "emacsclient", "-c", "-a", "emacs", NULL };
static const char *volumeupcmd[] = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+", NULL };
static const char *volumedowncmd[] = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-", NULL };
static const char *volumemutecmd[] = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL };
static const char *micmutecmd[] = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle", NULL };
static const char *brightnessupcmd[] = { "brightnessctl", "set", "+5%", NULL };
static const char *brightnessdowncmd[] = { "brightnessctl", "set", "5%-", NULL };

static const Key keys[] = {
	{ 0, XF86XK_AudioRaiseVolume, spawn, {.v = volumeupcmd } },
	{ 0, XF86XK_AudioLowerVolume, spawn, {.v = volumedowncmd } },
	{ 0, XF86XK_AudioMute, spawn, {.v = volumemutecmd } },
	{ 0, XF86XK_AudioMicMute, spawn, {.v = micmutecmd } },
	{ 0, XF86XK_MonBrightnessUp, spawn, {.v = brightnessupcmd } },
	{ 0, XF86XK_MonBrightnessDown, spawn, {.v = brightnessdowncmd } },
	{ MODKEY, XK_space, spawn, {.v = dmenucmd } },
	{ MODKEY, XK_Return, spawn, {.v = termcmd } },
	{ MODKEY, XK_e, spawn, {.v = emacscmd } },
	{ MODKEY, XK_b, togglebar, {0} },
	{ MODKEY, XK_j, focusstack, {.i = +1 } },
	{ MODKEY, XK_k, focusstack, {.i = -1 } },
	{ MODKEY, XK_i, incnmaster, {.i = +1 } },
	{ MODKEY, XK_p, incnmaster, {.i = -1 } },
	{ MODKEY, XK_h, setmfact, {.f = -0.05} },
	{ MODKEY, XK_l, setmfact, {.f = +0.05} },
	{ MODKEY|ShiftMask, XK_Return, zoom, {0} },
	{ MODKEY, XK_Tab, view, {0} },
	{ MODKEY, XK_q, killclient, {0} },
	{ MODKEY, XK_t, setlayout, {.v = &layouts[0]} },
	{ MODKEY, XK_f, setlayout, {.v = &layouts[1]} },
	{ MODKEY, XK_m, setlayout, {.v = &layouts[2]} },
	{ MODKEY, XK_d, setlayout, {0} },
	{ MODKEY|ShiftMask, XK_space, togglefloating, {0} },
	{ MODKEY, XK_0, view, {.ui = ~0 } },
	{ MODKEY|ShiftMask, XK_0, tag, {.ui = ~0 } },
	{ MODKEY, XK_comma, focusmon, {.i = -1 } },
	{ MODKEY, XK_period, focusmon, {.i = +1 } },
	{ MODKEY|ShiftMask, XK_comma, tagmon, {.i = -1 } },
	{ MODKEY|ShiftMask, XK_period, tagmon, {.i = +1 } },
	TAGKEYS(XK_1, 0)
	TAGKEYS(XK_2, 1)
	TAGKEYS(XK_3, 2)
	TAGKEYS(XK_4, 3)
	TAGKEYS(XK_5, 4)
	TAGKEYS(XK_6, 5)
	TAGKEYS(XK_7, 6)
	TAGKEYS(XK_8, 7)
	TAGKEYS(XK_9, 8)
	{ MODKEY|ShiftMask, XK_q, quit, {0} },
};

static const Button buttons[] = {
	{ ClkLtSymbol, 0, Button1, setlayout, {0} },
	{ ClkLtSymbol, 0, Button3, setlayout, {.v = &layouts[2]} },
	{ ClkWinTitle, 0, Button2, zoom, {0} },
	{ ClkStatusText, 0, Button2, spawn, {.v = termcmd } },
	{ ClkClientWin, MODKEY, Button1, movemouse, {0} },
	{ ClkClientWin, MODKEY, Button2, togglefloating, {0} },
	{ ClkClientWin, MODKEY, Button3, resizemouse, {0} },
	{ ClkTagBar, 0, Button1, view, {0} },
	{ ClkTagBar, 0, Button3, toggleview, {0} },
	{ ClkTagBar, MODKEY, Button1, tag, {0} },
	{ ClkTagBar, MODKEY, Button3, toggletag, {0} },
};

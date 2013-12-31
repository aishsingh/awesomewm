-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
vicious = require("vicious")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Alsa mixer library
require('couth.couth')
require('couth.alsa')
-- mpd
local lain = require("lain")
local tonumber = tonumber


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/default/theme.lua.grey")

-- This is used later as the default terminal and editor to run.
terminal = "xfce4-terminal"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
	names  = { "1", "2", "3", "4", "5", "6", "7" },  --{ "term", "www", "dev", "gfx", "media", "vm"},
	layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1]} --{ layouts[2], layouts[5], layouts[5], layouts[10], layouts[1], layouts[10]}
}
			      
for s = 1, screen.count() do
	tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ Wibox
markup = lain.util.markup
blue = "#D81860"--"#ad504b"--"#C28334"--"#6a9fb5"
red = "#bf4849"
gray = "#444444"
dateformat = " %b %d <span color='" .. blue .. "'>%I:%M </span>"

-- Create a textclock widget
mytextclock = awful.widget.textclock(dateformat, 60)
lain.widgets.calendar:attach(mytextclock)

-- MPD
mpdwidget = lain.widgets.mpd({
 	settings = function()
 		artist = mpd_now.artist .. " "
 		title  = mpd_now.title  .. " "
 		if mpd_now.state == "pause" then
 			artist = "mpd "
 			title  = "paused "
 		elseif mpd_now.state == "stop" then
 			artist = ""
     			title  = ""
 		end
 
         	widget:set_markup(artist .. markup(blue, title))
 	end
})

wifiwidget = wibox.widget.textbox()
vicious.register(wifiwidget, vicious.widgets.wifi, " Net <span color='" .. blue .. "'>${ssid}</span> ", 127, "wlp3s0")

--cpuwidget = wibox.widget.textbox()
--vicious.register(cpuwidget, vicious.widgets.cpu, " Cpu <span color='" .. blue .. "'>$1%</span> ", 13)

memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem, " Mem <span color='" .. blue .. "'>$2MB</span> ", 15)

batwidget = wibox.widget.textbox()
vicious.register(batwidget, vicious.widgets.bat, " Bat <span color='" .. blue .. "'>$2%</span> ", 41, "BAT0")

--pkgwidget = wibox.widget.textbox()
--vicious.register(pkgwidget, vicious.widgets.pkg, "[<span color='" .. blue .. "'>$1</span>] ", 7200, "Arch")

-- ALSA volume
volumewidget = lain.widgets.alsa({
	settings = function()
		header = " Vol "
        	vlevel  = volume_now.level

        	if volume_now.status == "off" then
        		vlevel = "[M] "
        	else
                	vlevel = vlevel .. " "
        	end
        	widget:set_markup(header .. markup(blue, vlevel))
        end
})


mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    -- left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    --left_layout:add(pkgwidget)
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mpdwidget)
    -- right_layout:add(wethwidget)
    right_layout:add(wifiwidget)
    --right_layout:add(cpuwidget)
    right_layout:add(memwidget)
    right_layout:add(volumewidget)
    right_layout:add(batwidget) 
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])
        
    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    --awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    --awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),
    
    awful.key({ modkey ,          }, "b", function ()
	    mywibox[mouse.screen].visible = not mywibox    [mouse.screen].visible
    end),

------- Couth audio control
    awful.key({ }, "XF86AudioLowerVolume",   function () couth.notifier:notify( couth.alsa:setVolume('Master','2dB-')) volumewidget.update() end),
    awful.key({ }, "XF86AudioRaiseVolume",   function () couth.notifier:notify( couth.alsa:setVolume('Master','2dB+')) volumewidget.update() end),
    awful.key({ }, "XF86AudioMute",          function () couth.notifier:notify( couth.alsa:setVolume('Master','toggle')) volumewidget.update() end),

    awful.key({ "Control" }, "XF86AudioLowerVolume",    function () couth.notifier:notify( couth.alsa:setVolume('Headphone','2dB-')) end),
    awful.key({ "Control" }, "XF86AudioRaiseVolume",    function () couth.notifier:notify( couth.alsa:setVolume('Headphone','2dB+')) end),
    awful.key({ "Control" }, "XF86AudioMute",           function () couth.notifier:notify( couth.alsa:setVolume('Headphone','toggle')) end),
-------- MPD
    awful.key({ },		"XF86AudioPlay", 
	function ()
		awful.util.spawn_with_shell("mpc toggle")
                mpdwidget.update()
        end),
    awful.key({ "Control" }, 	"XF86AudioPlay",
        function ()
                awful.util.spawn_with_shell("mpc stop")
                mpdwidget.update()
        end),
    awful.key({ }, 		"KP_Delete",
        function ()
                awful.util.spawn_with_shell("mpc prev")
                mpdwidget.update()
        end),
    awful.key({ }, 		"KP_Add",
        function ()
        	awful.util.spawn_with_shell("mpc next")
        	mpdwidget.update()
        end),
-------- Layout shortcut
    awful.key({ "Control" },	"Menu", 
    	function ()
		local screen = mouse.screen
                local tag = awful.tag.gettags(screen)[7]
                if tag then
                	awful.tag.viewonly(tag)
                end
        end),	

    awful.key({ "Control" },	"Return", 
    	function () 
		awful.util.spawn(terminal) 
	end),

    awful.key({ "Control" },	"backslash", awful.tag.history.restore),

--     awful.key( {}, "", 
--    	function () 
--		awful.util.spawn(terminal) 
--	end),

    -- Prompts
    awful.key( {}, "F12", 
    	function ()
		awful.prompt.run({ prompt = "Calculate: " }, mypromptbox[mouse.screen].widget,
		function (expr)
			local result = awful.util.eval("return (" .. expr .. ")")
			naughty.notify({ text = expr .. " = " .. result, timeout = 5 })
		end)
	end),

awful.key({ modkey, "Shift"   }, "r",
	function ()
	        awful.prompt.run({ prompt = "Run in terminal: " },
	        mypromptbox[mouse.screen].widget,
		function (...) awful.util.spawn(terminal .. [[ -e "zsh -c ']] .. ... .. [[;zsh -i'"]]) end,
		awful.completion.shell,
		awful.util.getdir("cache") .. "/history")
	end),

    awful.key({ modkey }, "r",     function () mypromptbox[mouse.screen]:run() end),
    --awful.key({ modkey },            "r",     function ()
--	        awful.util.spawn("dmenu_run -i -p 'Run ' -nb '" .. 
--		beautiful.bg_normal .. "' -nf '" .. beautiful.fg_normal .. 
--		"' -sb '" .. beautiful.bg_focus .. 
--		"' -sf '" .. beautiful.fg_focus .. "'") 
--	end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
    -- dmenu
    --awful.key({modkey }, "p", 
    --	function()
--		  awful.util.spawn_with_shell( "exe=`dmenu_path | dmenu_run -nf '" .. beautiful.fg_normal .. "' -nb '" .. beautiful.bg_normal .. "' -sf '" .. beautiful.fg_focus .. "' -sb '" .. beautiful.bg_focus .. "'` && exec $exe")
--    	end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
	    c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
--musicwidget:append_global_keys()
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "irssi" },
      properties = { tag = tags[1][6] } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    c.size_hints_honor = false
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", 
	function(c)
		c.border_color = beautiful.border_focus
		c.opacity = 1
	end)
client.connect_signal("unfocus", 
	function(c) 
		c.border_color = beautiful.border_normal 
		c.opacity = 0.95
	end)
-- }}}

couth.CONFIG.ALSA_CONTROLS = {
	'Master',
	'Headphone'
}

theme.tasklist_disable_icon = true
menubar.show_categories = false
menubar.geometry = {
	height = 15,
	width = 1920,
	x = 0,
	y = 0
}

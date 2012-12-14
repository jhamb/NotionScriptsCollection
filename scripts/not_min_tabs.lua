-- not_min_tabs.lua

-- Lua script for Notion aiming to hide the tab bar of frames not using the
-- styles "floating" or "transient".

-- Copyright 2012 Lukas Waymann <lb.waym@gmail.com>

-- This software is released under the terms of the MIT license. For more
-- information, see http://opensource.org/licenses/MIT

-- Enable this by adding dopath("not_min_tabs") to (e.g.) your cfg_notion.lua
-- and defining adapted "-alt" styles in your "look_something.lua" (usually
-- "frame-tiled-alt" with the argument "bar = "none"").

function hide_tabs(fr)  -- fr must be a WFrame.
    return function()
        fr:set_mode(string.sub(fr:mode(),
                    string.find(fr:mode(), "[^-]*")).."-alt")
    end
end

function show_tabs(fr)  -- fr must be a WFrame.
    return function()
        fr:set_mode(string.sub(fr:mode(), string.find(fr:mode(), "[^-]*")))
    end
end

function reconsider_tabs(fr)
    -- This Should leave us with "tiled" frames, "unknown" frames and their
   -- respective "-alt" variants.
    if fr:mode() == "floating" or fr:mode() == "transient" then
        return
    end

    if WMPlex.mx_count(fr) == 1 and not fr:mx_nth(0):is_tagged() then
        notioncore.defer(hide_tabs(fr))
    else
        notioncore.defer(show_tabs(fr))
    end
end

notioncore.get_hook("frame_managed_changed_hook"):add(
	 -- See http://notion.sourceforge.net/notionconf for the interface of the
	 -- type of the argument that will substitute table.
    function(table)
        reconsider_tabs(table.reg)
    end
)

-- Should be more reliable than changing the binding that invokes
-- WRegion.set_tagged() (META.."T")
notioncore.get_hook("region_notify_hook"):add(
    function(reg, context)
        if context == "tag" then
            reconsider_tabs(notioncore.find_manager(reg, "WFrame"))
        end
    end
)

-- WFrames that were not correctly reset to their normal syles (i.e. having
-- tabs) when exiting Notion the last time are now, at startup. This is
-- nescessary if Notion was exited while any WFrame contained exacly one client
-- window (that thus had no tab bar).
notioncore.get_hook("ioncore_post_layout_setup_hook"):add(
    function()
        notioncore.region_i(
            function(fr)
                notioncore.defer(reconsider_tabs(fr))
                return true
            end, "WFrame")
    end
)

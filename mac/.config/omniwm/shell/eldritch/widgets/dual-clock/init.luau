-- Eastern time follows America/New_York daylight saving rules.
-- Include both dates because UTC may already be on the following day.
interval = 15

local function clock(ctx, label, zone, color)
    local now = ctx.data.seconds
    local date = ctx.format.date(now, "EEEMMMd", zone) or "—"
    local time = ctx.format.date(now, "HHmm", zone) or "—"
    return ui.row{ gap = 5,
        ui.text{ text = label, color = color, weight = "semibold", size = 11 },
        ui.text{ text = date, color = "secondaryForeground", size = 11 },
        ui.text{ text = time, style = "mono", weight = "semibold", reserve = "00:00" } }
end

function render(ctx)
    local eastern = clock(ctx, "ET", "America/New_York", "accent")
    local utc = clock(ctx, "UTC", "UTC", "cyan")
    if ctx.data.bar.style.vertical then
        return ui.column{ gap = 4, eastern, utc }
    end
    return ui.row{ gap = 12, pad = 4,
        eastern,
        ui.box{ w = 1, h = 16, fill = "border" },
        utc }
end

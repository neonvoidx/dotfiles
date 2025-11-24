local colors = require("colors").sections.spaces
local icons = require "icons"
local icon_map = require "helpers.icon_map"

local function add_windows(space, space_name)
  sbar.exec(
    "yabai -m query --windows --space " .. space_name .. " | jq -r '.[] | select(.\"is-minimized\" == false) | .app'",
    function(windows)
      local icon_line = ""
      for app in windows:gmatch "[^\r\n]+" do
        local lookup = icon_map[app]
        local icon = ((lookup == nil) and icon_map["Default"] or lookup)
        icon_line = icon_line .. " " .. icon
      end

      sbar.animate("tanh", 10, function()
        space:set {
          label = {
            string = icon_line == "" and "—" or icon_line,
            padding_right = icon_line == "" and 8 or 12,
          },
        }
      end)
    end
  )
end

sbar.exec("yabai -m query --spaces | jq -r '.[].index'", function(spaces)
  for space_name in spaces:gmatch "[^\r\n]+" do
    -- Change display name for space 5 to "s"
    local display_name = space_name == "5" and "s" or space_name

    local space = sbar.add("item", "space." .. space_name, {
      icon = {
        string = display_name,
        color = colors.icon.color,
        highlight_color = colors.icon.highlight,
        padding_left = 8,
      },
      label = {
        font = "sketchybar-app-font:Regular:14.0",
        string = "",
        color = colors.label.color,
        highlight_color = colors.label.highlight,
        y_offset = -1,
      },
      click_script = "yabai -m space --focus " .. space_name,
      padding_left = space_name == "1" and 0 or 4,
    })

    add_windows(space, space_name)

    -- Initialize space highlight state based on current active space
    sbar.exec("yabai -m query --spaces --space | jq -r '.index'", function(current_space)
      current_space = current_space:gsub("%s+", "")
      local selected = current_space == space_name

      space:set {
        icon = { highlight = selected },
        label = { highlight = selected },
      }

      if selected then
        space:set {
          background = {
            shadow = {
              distance = 4,
            },
          },
        }
      end
    end)

    space:subscribe("space_change", function(env)
      -- Get the current space ID from yabai
      sbar.exec("yabai -m query --spaces --space | jq -r '.index'", function(current_space)
        -- Remove any newlines
        current_space = current_space:gsub("%s+", "")
        local selected = current_space == space_name

        space:set {
          icon = { highlight = selected },
          label = { highlight = selected },
        }

        if selected then
          sbar.animate("tanh", 8, function()
            space:set {
              background = {
                shadow = {
                  distance = 0,
                },
              },
              y_offset = -4,
              padding_left = 8,
              padding_right = 0,
            }
            space:set {
              background = {
                shadow = {
                  distance = 4,
                },
              },
              y_offset = 0,
              padding_left = 4,
              padding_right = 4,
            }
          end)
        end
      end)
    end)

    space:subscribe("window_focus", function()
      add_windows(space, space_name)
    end)

    space:subscribe("application_launched", function()
      add_windows(space, space_name)
    end)

    space:subscribe("application_terminated", function()
      add_windows(space, space_name)
    end)

    space:subscribe("window_created", function()
      add_windows(space, space_name)
    end)

    space:subscribe("window_destroyed", function()
      add_windows(space, space_name)
    end)

    space:subscribe("mouse.clicked", function()
      sbar.animate("tanh", 8, function()
        space:set {
          background = {
            shadow = {
              distance = 0,
            },
          },
          y_offset = -4,
          padding_left = 8,
          padding_right = 0,
        }
        space:set {
          background = {
            shadow = {
              distance = 4,
            },
          },
          y_offset = 0,
          padding_left = 4,
          padding_right = 4,
        }
      end)
    end)
  end
end)

local spaces_indicator = sbar.add("item", {
  icon = {
    padding_left = 8,
    padding_right = 9,
    string = icons.switch.on,
    color = colors.indicator,
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 8,
  },
  padding_right = 8,
})

spaces_indicator:subscribe("swap_menus_and_spaces", function()
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set {
    icon = { string = currently_on and icons.switch.off or icons.switch.on },
  }
end)

spaces_indicator:subscribe("mouse.clicked", function()
  sbar.animate("tanh", 8, function()
    spaces_indicator:set {
      background = {
        shadow = {
          distance = 0,
        },
      },
      y_offset = -4,
      padding_left = 8,
      padding_right = 4,
    }
    spaces_indicator:set {
      background = {
        shadow = {
          distance = 4,
        },
      },
      y_offset = 0,
      padding_left = 4,
      padding_right = 8,
    }
  end)

  sbar.trigger "swap_menus_and_spaces"
end)

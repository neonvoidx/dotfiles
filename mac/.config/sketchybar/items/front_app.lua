local colors = require("colors").sections.front_app

local front_app = sbar.add("item", "front_app", {
  display = "active",
  position = "center",
  icon = { drawing = false },
  label = {
    color = colors.label,
    padding_left = 15,
    padding_right = 15,
    font = {
      size = 16.0,
    },
  },
  background = {
    border_color = colors.border,
    border_width = 1,
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set { label = { string = env.INFO } }
end)

front_app:subscribe("mouse.clicked", function()
  sbar.trigger "swap_menus_and_spaces"
end)

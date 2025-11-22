local colors = require("colors").sections.bar

sbar.bar {
  topmost = "window",
  height = 30,
  notch_display_height = 41,
  padding_right = 12,
  padding_left = 12,
  margin = -1,
  corner_radius = 5,
  y_offset = -1,
  blur_radius = 25,
  border_color = colors.border,
  border_width = 0,
  color = colors.bg,
}

local M = {}

local with_alpha = function(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then
    return color
  end
  return (color & 0x00FFFFFF) | (math.floor(alpha * 255.0) << 24)
end

local transparent = 0x00000000

local eldritch = {
  black = 0xff212337,
  white = 0xffebfafa,
  red = 0xfff16c75,
  pink = 0xfff265b5,
  green = 0xff37f499,
  blue = 0xff04d1f9,
  yellow = 0xfff1fc79,
  orange = 0xfff7c67f,
  magenta = 0xffa48cf2,
  grey = 0xff7081d0,
  dark_purple = 0xff7081d0,
  transparent = 0x00000000,

  bar = {
    bg = 0xf0212337,
    border = 0xffa48cf2,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490,
  },
  bg1 = 0xff212337,
  bg2 = 0xff323449,
}

M.sections = {
  -- Core Components
  bar = {
    bg = with_alpha(eldritch.bar.bg, 0.5),
    border = eldritch.bar.border,
  },
  item = {
    bg = eldritch.bar.bg,
    border = eldritch.blue,
    text = eldritch.white,
  },
  popup = {
    bg = with_alpha(eldritch.bar.bg, 0.9),
    border = eldritch.bar.border,
  },

  -- Items
  apple = eldritch.grey,
  media = { label = eldritch.red },
  calendar = { label = eldritch.dark_purple },
  front_app = { label = eldritch.blue, border = eldritch.magenta },
  spaces = {
    icon = {
      color = eldritch.white,
      highlight = eldritch.green,
    },
    label = {
      color = eldritch.white,
      highlight = eldritch.green,
    },
    indicator = eldritch.green,
  },
  widgets = {
    battery = {
      low = eldritch.red,
      mid = eldritch.yellow,
      high = eldritch.green,
    },
    wifi = {
      icon = eldritch.blue,
    },
    volume = {
      icon = eldritch.magenta,
      popup = {
        item = eldritch.white,
        highlight = eldritch.green,
        bg = with_alpha(eldritch.bar.bg, 0.9),
      },
      slider = {
        highlight = eldritch.white,
        bg = with_alpha(eldritch.bar.bg, 0.9),
        border = eldritch.bar.border,
      },
    },
    messages = { icon = eldritch.white },
  },
}

return M

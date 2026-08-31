-- Catppuccin Mocha palette, kept from the previous shell profiles.
return {
  black = 0xff11111b, -- crust: inner item border
  white = 0xffcdd6f4, -- text
  subtext = 0xffa6adc8,
  red = 0xfff38ba8,
  green = 0xffa6e3a1,
  blue = 0xff89b4fa,
  yellow = 0xfff9e2af,
  orange = 0xfffab387,
  magenta = 0xffcba6f7,
  grey = 0xff6c7086, -- overlay0: dim borders and unselected labels
  transparent = 0x00000000,

  bar = {
    bg = 0xf01e1e2e, -- base with alpha, lets blur_radius show through
    border = 0xff45475a,
  },
  popup = {
    bg = 0xc0181825, -- mantle with alpha
    border = 0xff45475a,
  },
  bg1 = 0xff313244, -- surface0: item / bracket backgrounds
  bg2 = 0xff45475a, -- surface1: outer borders, slider tracks

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}

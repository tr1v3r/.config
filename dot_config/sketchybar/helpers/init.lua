-- Runtime bootstrap: make requires work regardless of the cwd sketchybar
-- started us with, load the SbarLua module, and build the vendored C event
-- providers (best effort — a missing compiler only disables the cpu graph).
local home = os.getenv("HOME") or ""
local config_dir = os.getenv("CONFIG_DIR") or (home .. "/.config/sketchybar")

package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path
package.cpath = package.cpath .. ";" .. home .. "/.local/share/sketchybar_lua/?.so"

os.execute("(cd \"" .. config_dir .. "/helpers\" && make >/dev/null 2>&1)")

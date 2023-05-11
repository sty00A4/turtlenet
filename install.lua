LINK = "https://raw.githubusercontent.com/sty00A4/turtlenet/main/"
local function download(path, prefix)
    if type(prefix) ~= "string" then prefix = "turtlenet/" end
    print("Downloading "..prefix..path..":")
    shell.run(("wget %s%s %s%s"):format(LINK, path, prefix, path))
end
download "apps/client/init.lua"
download "apps/server/client.lua"
download "apps/server/init.lua"
download "apps/server/log.lua"
download "apps/server/transform.lua"
download "gui/button.lua"
download "gui/container.lua"
download "gui/element.lua"
download "gui/init.lua"
download "gui/input.lua"
download "gui/text.lua"
download "picolua/bytecode.lua"
download "picolua/compiler.lua"
download "picolua/init.lua"
download "picolua/lexer.lua"
download "picolua/location.lua"
download "picolua/nodes.lua"
download "picolua/parser.lua"
download "picolua/program.lua"
download "picolua/tokens.lua"
download ".gitignore"
download "init.lua"
download "install.lua"
download "LICENSE"
download "README.md"
download "turt.lua"

download("turt.lua", "")

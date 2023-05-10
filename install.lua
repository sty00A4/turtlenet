LINK = "https://raw.githubusercontent.com/sty00A4/turtlenet/main/"
local function download(path, prefix)
    if type(prefix) ~= "string" then prefix = "turtlenet/" end
    print("Downloading "..prefix..path..":")
    shell.run(("wget %s%s %s%s"):format(LINK, path, prefix, path))
end
download "client/init.lua"
download "gui/button.lua"
download "gui/element.lua"
download "gui/init.lua"
download "gui/input.lua"
download "gui/prompt.lua"
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
download "server/client.lua"
download "server/init.lua"
download "server/log.lua"
download "server/transform.lua"
download "init.lua"
download "LICENSE"
download "README.md"

download("turt.lua", "")
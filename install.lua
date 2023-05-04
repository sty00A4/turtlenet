LINK = "https://raw.githubusercontent.com/sty00A4/turtlenet/main/"
local function download(path, prefix)
    if type(prefix) ~= "string" then prefix = "turtlenet/" end
    print("Downloading "..prefix..path..":")
    shell.run(("wget %s%s %s%s"):format(LINK, path, prefix, path))
end
download "client/init.lua"
download "server/client.lua"
download "server/init.lua"
download "server/log.lua"
download "server/transform.lua"
download "init.lua"
download "LICENSE"
download "README.md"

download("turt.lua", "")
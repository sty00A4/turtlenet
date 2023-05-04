LINK = "https://raw.githubusercontent.com/sty00A4/turtlenet/main/"
local function download(path, prefix)
    if not prefix then prefix = "turtlenet/" end
    term.write("Downloading "..path.."... ")
    shell.run(("wget %s%s turtlenet/%s"):format(LINK, path, path))
    print("Done! ")
end
download "client/init.lua"
download "server/client.lua"
download "server/init.lua"
download "server/log.lua"
download "server/transform.lua"
download "init.lua"
download "LICENSE"
download "README.md"

download("turtlenet.lua", "")
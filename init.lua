NET_PROTOCOL = "turtlenet"
SERVER_TIMEOUT = 0.5
local server = require "turtlenet.server"
local client = require "turtlenet.client"
local picolua = require "turtlenet.picolua"
return {
    server = server,
    client = client,
    picolua = picolua
}
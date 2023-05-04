NET_PROTOCOL = "turtlenet"
SERVER_TIMEOUT = 10
local server = require "turtlenet.server"
local client = require "turtlenet.client"
local log = require "turtlenet.log"
return {
    server = server,
    client = client,
    log = log
}
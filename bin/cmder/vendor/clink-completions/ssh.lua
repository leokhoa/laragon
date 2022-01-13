local w = require('tables').wrap
local parser = clink.arg.new_parser

local function read_lines (filename)
    local lines = w({})
    local f = io.open(filename)
    if not f then return lines end

    for line in f:lines() do table.insert(lines, line) end

    f:close()
    return lines
end

-- read all Host entries in the user's ssh config file
local function list_ssh_hosts()
    return read_lines(clink.get_env("userprofile") .. "/.ssh/config")
        :map(function (line)
            return line:match('^Host%s+(.*)$')
        end)
        :filter()
end

local function list_known_hosts()
    return read_lines(clink.get_env("userprofile") .. "/.ssh/known_hosts")
        :map(function (line)
            return line:match('^([%w.]*).*')
        end)
        :filter()
end

local hosts = function (token)  -- luacheck: no unused args
    return list_ssh_hosts()
        :concat(list_known_hosts())
end

local ssh_hosts_parser = parser({hosts})

clink.arg.register_parser("ssh", ssh_hosts_parser)

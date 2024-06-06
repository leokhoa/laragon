local parser = clink.arg.new_parser
local net_parser = parser(
    {
        "accounts" .. parser("/forcelogoff:", "/forcelogoff:no", "/domain",
                             "/maxpwage:", "/maxpwage:unlimited", "/minpwage:",
                             "/minpwlen:","/uniquepw:"),
        "computer" .. parser({"*" .. parser("/add", "/del")}),
        "config" .. parser({"server", "workstation"}),
        "continue",
        "file",
        "group",
        "helpmsg",
        "localgroup",
        "pause",
        "session" .. parser({parser("/delete", "/list")}),
        "share",
        "start",
        "statistics" .. parser({"server", "workstation"}),
        "stop",
        "time" .. parser("/domain", "/rtsdomain", "/set"),
        "use" .. parser("/user:", "/smartcard", "/savecred", "/delete",
                       "/persistent:yes", "/persistent:no"),
        "user",
        "view" .. parser("/cache", "/all", "/domain")
    },
    "/?"
)

local help_parser = parser(
    {
        "help" .. parser({net_parser:flatten_argument(1), "names", "services", "syntax"})
    }
)

clink.arg.register_parser("net", net_parser)
clink.arg.register_parser("net", help_parser)

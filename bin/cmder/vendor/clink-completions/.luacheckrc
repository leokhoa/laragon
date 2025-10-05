return {
    exclude_files = { ".lua", "modules/JSON.lua", "lua_modules" },
    files = {
        spec = { std = "+busted" },
    },
    globals = { "clink", "rl_state", "rl", "settings", "log", "path" }
}

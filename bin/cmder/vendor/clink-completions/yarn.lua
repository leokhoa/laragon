-- preamble: common routines

local JSON = require("JSON")

-- silence JSON parsing errors
function JSON:assert () end  -- luacheck: no unused args

local w = require('tables').wrap
local matchers = require('matchers')

---
 -- Queries config options value using 'yarn config get' call
 -- @param  {string}  config_entry  Config option name
 -- @return {string}  Config value for specific option or
 --   empty string in case of any error
---
local function get_yarn_config_value (config_entry)
    assert(config_entry and type(config_entry) == "string" and #config_entry > 0,
        "get_yarn_config_value: config_entry param should be non-empty string")

    local proc = io.popen("yarn config get "..config_entry.." 2>nul")
    if not proc then return "" end

    local value = proc:read()
    proc:close()

    return value or nil
end

local modules = matchers.create_dirs_matcher('node_modules/*')

local globals_location = nil
local global_modules_matcher = nil
local function global_modules(token)
    -- If we already have matcher then just return it
    if global_modules_matcher then return global_modules_matcher(token) end

    -- If token starts with . or .. or has path delimiter then return empty
    -- result and do not create a matcher so only fs paths will be completed
    if (token:match('^%.(%.)?') or token:match('[%\\%/]+')) then return {} end

    -- otherwise try to get cache location and return empty table if failed
    globals_location = globals_location or get_yarn_config_value("prefix")
    if not globals_location then return {} end

    -- Create a new matcher, save it in module's variable for further usage and return it
    global_modules_matcher = matchers.create_dirs_matcher(globals_location..'/node_modules/*')
    return global_modules_matcher(token)
end

-- A function that matches all files in bin folder. See #74 for rationale
local bins = matchers.create_files_matcher('node_modules/.bin/*.')

-- Reads package.json in current directory and extracts all "script" commands defined
local function scripts(token)  -- luacheck: no unused args

    -- Read package.json first
    local package_json = io.open('package.json')
    -- If there is no such file, then close handle and return
    if package_json == nil then return w() end

    -- Read the whole file contents
    local package_contents = package_json:read("*a")
    package_json:close()

    local package_scripts = JSON:decode(package_contents).scripts
    return w(package_scripts):keys()
end

local parser = clink.arg.new_parser

-- end preamble


local add_parser = parser(
    "--dev", "-D",
    "--exact", "-E",
    "--optional", "-O",
    "--peer", "-P",
    "--tilde", "-T"
)

local yarn_parser = parser({
    "add"..add_parser,
    "bin",
    "cache"..parser({
        "clean",
        "dir",
        "ls"
    }),
    "check"..parser("--integrity"),
    "clean",
    "config"..parser({
        "delete",
        "get",
        "list",
        "set"
    }),
    "generate-lock-entry",
    "global"..parser({
        "add"..add_parser,
        "bin",
        "ls",
        "remove"..parser({modules}),
        "upgrade"..parser({modules})
    }),
    "help",
    "info",
    "init"..parser("--yes", "-y"),
    "install",
    "licenses"..parser({"generate-disclaimer", "ls"}),
    "link"..parser({matchers.files, global_modules}),
    "login",
    "logout",
    "ls"..parser("--depth"),
    "outdated"..parser({modules}),
    "owner"..parser({"add", "ls", "rm"}),
    "pack"..parser("--filename", "-f"),
    "publish"..parser(
        "--access"..parser({"public", "restricted"}),
        "--message",
        "--new-version",
        "--no-git-tag-version",
        "--tag"
    ),
    "remove"..parser({modules}),
    "run"..parser({bins, scripts}),
    "self-update",
    "tag"..parser({"add", "ls", "rm"}),
    "team"..parser({"add", "create", "destroy", "ls", "rm"}),
    "test",
    "unlink"..parser({modules}),
    "upgrade"..parser({modules}, "--ignore-engines"),
    "upgrade-interactive",
    "version"..parser(
        "--message",
        "--new-version",
        "--no-git-tag-version"
    ),
    "versions",
    "why"..parser({modules})
    },
    "-h",
    "-v",
    "--cache-folder",
    "--flat",
    "--force",
    "--global-folder",
    "--har",
    "--help",
    "--https-proxy",
    "--ignore-engines",
    "--ignore-optional",
    "--ignore-platform",
    "--ignore-scripts",
    "--json",
    "--modules-folder",
    "--mutex",
    "--no-bin-links",
    "--no-lockfile",
    "--offline",
    "--no-emoji",
    "--no-progress",
    "--prefer-offline",
    "--proxy",
    "--pure-lockfile",
    "--prod",
    "--production",
    "--strict-semver",
    "--version"
)

clink.arg.register_parser("yarn", yarn_parser)


local gitutil = require('gitutil')

-- TODO: cache config based on some modification indicator (system mtime, hash)

-- this code is stolen from https://github.com/Dynodzzo/Lua_INI_Parser/blob/master/LIP.lua
-- Resolve licensing issues before exposing
local function load_ini(fileName)
    assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.')
    local file = io.open(fileName, 'r')
    if not file then return nil end

    local data = {};
    local section;
    for line in file:lines() do
        local tempSection = line:match('^%[([^%[%]]+)%]$');
        if tempSection then
            section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
            data[section] = data[section] or {}
        end

        local param, value = line:match('^%s-([%w|_]+)%s-=%s+(.+)$')
        if(param and value ~= nil)then
            if(tonumber(value))then
                value = tonumber(value);
            elseif(value == 'true')then
                value = true;
            elseif(value == 'false')then
                value = false;
            end
            if(tonumber(param))then
                param = tonumber(param);
            end
            data[section][param] = value
        end
    end
    file:close();
    return data;
end

---
 -- Escapes every non-alphanumeric character in string with % symbol. This is required
 -- because string.gsub treats plain strings with some symbols (e.g. dashes) as regular
 -- expressions (taken from http://stackoverflow.com/a/34953646)
 -- @param {string} text Text to escape
 -- @returns {string} Escaped text
---
local function escape(text)
    return text and text:gsub("([^%w])", "%%%1") or ""
end

local git = {}
git.get_config = function (git_dir, section, param)
    if not git_dir then return nil end
    if (not param) or (not section) then return nil end

    local git_config = load_ini(git_dir..'/config')
    if not git_config then return nil end

    return git_config[section] and git_config[section][param] or nil
end

local function git_prompt_filter()
    -- Check for Cmder configured Git Status Opt In/Out - See: https://github.com/cmderdev/cmder/issues/2484
    if cmderGitStatusOptIn == false then return false end  -- luacheck: globals cmderGitStatusOptIn

    local git_dir = gitutil.get_git_dir()
    if not git_dir then return false end

    -- if we're inside of git repo then try to detect current branch
    local branch = gitutil.get_git_branch(git_dir)
    if not branch then return false end

    -- for remote and ref resolution algorithm see https://git-scm.com/docs/git-push
    local remote_to_push = git.get_config(git_dir, 'branch "'..branch..'"', 'remote') or ''
    local remote_ref = git.get_config(git_dir, 'remote "'..remote_to_push..'"', 'push') or
        git.get_config(git_dir, 'push', 'default')

    local text = remote_to_push
    if (remote_ref) then text = text..'/'..remote_ref end

    if (text == '') then
      clink.prompt.value = clink.prompt.value:gsub(escape('('..branch), '%1'..text)
    else
      clink.prompt.value = clink.prompt.value:gsub(escape('('..branch), '%1 -> '..text)
    end

    return false
end

-- Register filter with priority 60 which is greater than
-- Cmder's git prompt filters to override them
clink.prompt.register_filter(git_prompt_filter, 60)

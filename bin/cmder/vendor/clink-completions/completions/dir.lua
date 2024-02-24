--------------------------------------------------------------------------------
-- Usage:
--
-- Argmatcher for DIR.  Uses delayinit to support localized help text.

--------------------------------------------------------------------------------
local clink_version = require('clink_version')
if not clink_version.supports_argmatcher_delayinit then
    print("dir.lua argmatcher requires a newer version of Clink; please upgrade.")
    return
end

local mcf = require('multicharflags')

--------------------------------------------------------------------------------
local function add_pending(pending, flags, descriptions, hideflags)
    if pending then
        local main = pending.flag:lower()
        local alt = pending.flag
        table.insert(flags, { flag=main })
        if main ~= alt then
            table.insert(flags, { flag=alt })
            table.insert(hideflags, alt)
        end
        local desc = pending.desc:gsub('%.+$', '')
        descriptions[main] = { desc }
        if pending.charflags then
            local arg = mcf.addcharflagsarg(clink.argmatcher(), pending.charflags)
            main = main .. ':'
            alt = alt .. ':'
            table.insert(flags, { flag=main, arg=arg })
            if main ~= alt then
                table.insert(flags, { flag=alt, arg=arg })
                table.insert(hideflags, alt)
            end
            descriptions[main] = { pending.display, desc }
        end
    end
end

--------------------------------------------------------------------------------
local inited

--------------------------------------------------------------------------------
local function add_charflags(pending, indent, line)
    if indent < pending.indent then
        return
    end

    local lhs, rhs = line:match('^([^ ]  [^ ].+  +)([^ ]  [^ ].+)$')
    if not lhs then
        lhs = line:match('^([^ ]  [^ ].+)$')
    end
    if not lhs then
        return
    end

    for _, x in ipairs({lhs, rhs}) do
        local c, desc = x:match('^([^ ])  ([^ ].+)$')
        if not c then
            break
        end
        local i = (_ > 1 or c == '-') and (#pending.charflags + 1) or (#pending.charflags / 2 + 1)
        table.insert(pending.charflags, i, { c:lower(), desc })
    end

    return true
end

--------------------------------------------------------------------------------
local function delayinit(argmatcher)
    if inited then
        return
    end
    inited = true

    local file = io.popen('dir /?')
    if not file then
        return
    end

    local flags = {}
    local descriptions = {}
    local hideflags = {}
    local pending

    local section = 'header'
    for line in file:lines() do
        if unicode.fromcodepage then -- luacheck: no global
            line = unicode.fromcodepage(line) -- luacheck: no global
        end
        if section == 'header' and line:match('^ +/') then
            section = 'flags'
        end
        if section == 'flags' then
            local add
            local indent, flag, pad, desc = line:match('^( +)(/[^ ]+)( +)([^ ].*)$')

            if flag then
                add_pending(pending, flags, descriptions, hideflags)
                pending = {}
                pending.indent = #indent + #flag + #pad
                pending.flag = flag
                pending.desc = desc:gsub(' +$', '')
            elseif pending then
                indent, desc = line:match('^( +)([^ ].*)$')
                if indent and #indent == (pending.indent or 0) then
                    pending.desc = pending.desc .. ' ' .. desc:gsub(' +$', '')
                elseif indent and #indent >= 2 and #indent < 8 then
                    local display
                    display, pad, desc = desc:match('^([^ ]+)( +)([^ ].+)$')
                    indent = #indent + #display + #pad
                    if display and indent >= pending.indent then
                        pending.display = display
                        pending.charflags = pending.charflags or { caseless=true }
                        add = not add_charflags(pending, indent, desc)
                    else
                        add = true
                    end
                elseif indent and pending.charflags then
                    add = not add_charflags(pending, #indent, desc)
                else
                    add = true
                end
            else
                add = true
            end

            if add then
                add_pending(pending, flags, descriptions, hideflags)
                pending = nil
            end
        end
    end
    add_pending(pending, flags, descriptions, hideflags)

    file:close()

    local actual_flags = {}
    for _, f in ipairs(flags) do
        if f.arg then
            table.insert(actual_flags, f.flag .. f.arg)
        else
            table.insert(actual_flags, f.flag)
        end
    end

    argmatcher:addflags(actual_flags)
    argmatcher:adddescriptions(descriptions)
    argmatcher:hideflags(hideflags)
end

--------------------------------------------------------------------------------
clink.argmatcher('dir'):setdelayinit(delayinit)

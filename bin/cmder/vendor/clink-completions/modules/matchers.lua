
local exports = {}

local path = require('path')
local w = require('tables').wrap

exports.dirs = function(word)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = word:find("[\\/:][^\\/:]*$")
    if i then
        prefix = word:sub(1, i)
    end
    local include_dots = word:find("%.+$") ~= nil

    -- Find matches.
    local matches = w(clink.find_dirs(word.."*", true))
    :filter(function (dir)
        return clink.is_match(word, prefix..dir) and
            (include_dots or path.is_real_dir(dir))
    end)
    :map(function(dir)
        return prefix..dir
    end)

    -- If there was no matches but word is a dir then use it as the single match.
    -- Otherwise tell readline that matches are files and it will do magic.
    if #matches == 0 and clink.is_dir(rl_state.text) then
        return {rl_state.text}
    end

    clink.matches_are_files()
    return matches
end

exports.files = function (word)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = word:find("[\\/:][^\\/:]*$")
    if i then
        prefix = word:sub(1, i)
    end

    -- Find matches.
    local matches = w(clink.find_files(word.."*", true))
    :filter(function (file)
        return clink.is_match(word, prefix..file)
    end)
    :map(function(file)
        return prefix..file
    end)

    -- Tell readline that matches are files and it will do magic.
    if #matches ~= 0 then
        clink.matches_are_files()
    end

    return matches
end

exports.create_dirs_matcher = function (dir_pattern, show_dotfiles)
    return function (token)
        return w(clink.find_dirs(dir_pattern))
        :filter(function(dir)
            return clink.is_match(token, dir) and (path.is_real_dir(dir) or show_dotfiles)
        end )
    end
end

exports.create_files_matcher = function (file_pattern)
    return function (token)
        return w(clink.find_files(file_pattern))
        :filter(function(file)
            -- Filter out '.' and '..' entries as well
            return clink.is_match(token, file) and path.is_real_dir(file)
        end )
    end
end

return exports

local path = require('path')

local exports = {}

---
 -- Resolves closest .git directory location.
 -- Navigates subsequently up one level and tries to find .git directory
 -- @param  {string} path Path to directory will be checked. If not provided
 --                       current directory will be used
 -- @return {string} Path to .git directory or nil if such dir not found
exports.get_git_dir = function (start_dir)

    -- Checks if provided directory contains '.git' directory
    -- and returns path to that directory
    local function has_git_dir(dir)
        return #clink.find_dirs(dir..'/.git') > 0 and dir..'/.git'
    end

    -- checks if directory contains '.git' _file_ and if it does
    -- parses it and returns a path to git directory from that file
    local function has_git_file(dir)
        local gitfile = io.open(dir..'/.git')
        if not gitfile then return false end

        local git_dir = gitfile:read():match('gitdir: (.*)')
        gitfile:close()

        if not git_dir then return false end
        -- If found path is absolute don't prepend initial
        -- directory - return absolute path value
        return path.is_absolute(git_dir) and git_dir
            or dir..'/'..git_dir
    end

    -- Set default path to current directory
    if not start_dir or start_dir == '.' then start_dir = clink.get_cwd() end

    -- Calculate parent path now otherwise we won't be
    -- able to do that inside of logical operator
    local parent_path = path.pathname(start_dir)

    return has_git_dir(start_dir)
        or has_git_file(start_dir)
        -- Otherwise go up one level and make a recursive call
        or (parent_path ~= start_dir and exports.get_git_dir(parent_path) or nil)
end

exports.get_git_common_dir = function (start_dir)
    local git_dir = exports.get_git_dir(start_dir)
    if not git_dir then return git_dir end
    local commondirfile = io.open(git_dir..'/commondir')
    if commondirfile then
        -- If there's a commondir file, we're in a git worktree
        local commondir = commondirfile:read()
        commondirfile.close()
        return path.is_absolute(commondir) and commondir
            or git_dir..'/'..commondir
    end
    return git_dir
end

---
 -- Find out current branch
 -- @return {nil|git branch name}
---
exports.get_git_branch = function (dir)
    local git_dir = dir or exports.get_git_dir()

    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_dir and io.open(git_dir..'/HEAD')
    if not head_file then return end

    local HEAD = head_file:read()
    head_file:close()

    -- if HEAD matches branch expression, then we're on named branch
    -- otherwise it is a detached commit
    local branch_name = HEAD:match('ref: refs/heads/(.+)')
    return branch_name or 'HEAD detached at '..HEAD:sub(1, 7)
end

return exports

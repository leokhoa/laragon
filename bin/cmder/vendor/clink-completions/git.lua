-- preamble: common routines

local path = require('path')
local git = require('gitutil')
local matchers = require('matchers')
local w = require('tables').wrap
local parser = clink.arg.new_parser

---
 -- Lists remote branches based on packed-refs file from git directory
 -- @param string [dir]  Directory where to search file for
 -- @return table  List of remote branches
local function list_packed_refs(dir)
    local result = w()
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return result end

    local packed_refs_file = io.open(git_dir..'/packed-refs')
    if packed_refs_file == nil then return {} end

    for line in packed_refs_file:lines() do
        -- SHA is 40 char length + 1 char for space
        if #line > 41 then
            local match = line:sub(41):match('refs/remotes/(.*)')
            if match then table.insert(result, match) end
        end
    end

    packed_refs_file:close()
    return result
end

local function list_remote_branches(dir)
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return w() end

    return w(path.list_files(git_dir..'/refs/remotes', '/*',
        --[[recursive=]]true, --[[reverse_separator=]]true))
    :concat(list_packed_refs(git_dir))
    :sort():dedupe()
end

---
 -- Lists local branches for git repo in git_dir directory.
 --
 -- @param string [dir]  Git directory, where to search for remote branches
 -- @return table  List of branches.
local function list_local_branches(dir)
    local git_dir = dir or git.get_git_common_dir()
    if not git_dir then return w() end

    local result = w(path.list_files(git_dir..'/refs/heads', '/*',
        --[[recursive=]]true, --[[reverse_separator=]]true))

    return result
end

local branches = function (token)
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    return list_local_branches(git_dir)
    :filter(function(branch)
        return clink.is_match(token, branch)
    end)
end

local function alias(token)
    local res = w()

    -- Try to resolve .git directory location
    local git_dir = git.get_git_dir()

    if git_dir == nil then return res end

    local f = io.popen("git config --get-regexp alias 2>nul")
    if f == nil then return {} end

    for line in f:lines() do
        local s = line:find(" ", 1, true)
        local alias_name = line:sub(7, s - 1)
        local start = alias_name:find(token, 1, true)
        if start and start == 1 then
            table.insert(res, alias_name)
        end
    end

    f:close()

    return res
end

local function remotes(token)  -- luacheck: no unused args
    local result = w()
    local git_dir = git.get_git_common_dir()
    if not git_dir then return result end

    local git_config = io.open(git_dir..'/config')
    -- if there is no gitconfig file (WAT?!), return empty list
    if git_config == nil then return result end

    for line in git_config:lines() do
        local remote = line:match('%[remote "(.*)"%]')
        if (remote) then
            table.insert(result, remote)
        end
    end

    git_config:close()
    return result
end

local function local_or_remote_branches(token)
    -- Try to resolve .git directory location
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    return list_local_branches(git_dir)
    :concat(list_remote_branches(git_dir))
    :filter(function(branch)
        return clink.is_match(token, branch)
    end)
end

local function checkout_spec_generator(token)
    local files = matchers.files(token)
        :filter(function(file)
            return path.is_real_dir(file)
        end)

    local git_dir = git.get_git_common_dir()

    local local_branches = branches(token)
    local remote_branches = list_remote_branches(git_dir)
        :filter(function(branch)
            return clink.is_match(token, branch)
        end)

    local predicted_branches = list_remote_branches(git_dir)
        :map(function (remote_branch)
            return remote_branch:match('.-/(.+)')
        end)
        :filter(function(branch)
            return branch
                and clink.is_match(token, branch)
                -- Filter out those predictions which are already exists as local branches
                and not local_branches:contains(branch)
        end)

    if (#local_branches + #remote_branches + #predicted_branches) == 0 then return files end

    -- if there is any refspec that matches token then:
    --   * disable readline's filename completion, otherwise we'll get a list of these specs
    --     threaten as list of files (without 'path' part), ie. 'some_branch' instead of 'my_remote/some_branch'
    --   * create display filter for completion table to append path separator to each directory entry
    --     since it is not added automatically by readline (see previous point)
    clink.matches_are_files(0)
    clink.match_display_filter = function ()
        return files:map(function(file)
            return clink.is_dir(file) and file..'\\' or file
        end)
        :concat(local_branches)
        :concat(predicted_branches:map(function(branch) return '*'..branch end))
        :concat(remote_branches)
    end

    return files
        :concat(local_branches)
        :concat(predicted_branches)
        :concat(remote_branches)
end

local function push_branch_spec(token)
    local git_dir = git.get_git_common_dir()
    if not git_dir then return w() end

    local plus_prefix = token:sub(0, 1) == '+'
    -- cut out leading '+' symbol as it is a part of branch spec
    local branch_spec = plus_prefix and token:sub(2) or token
    -- check if there a local/remote branch separator
    local s, e = branch_spec:find(':')

    -- starting from here we have 2 options:
    -- * if there is no branch separator complete word with local branches
    if not s then
        local b = branches(branch_spec)

        -- setup display filter to prevent display '+' symbol in completion list
        clink.match_display_filter = function ()
            return b
        end

        return b:map(function(branch)
            -- append '+' to results if it was specified
            return plus_prefix and '+'..branch or branch
        end)
    else
    -- * if there is ':' separator then we need to complete remote branch
        local local_branch_spec = branch_spec:sub(1, s - 1)
        local remote_branch_spec = branch_spec:sub(e + 1)

        -- TODO: show remote branches only for remote that has been specified as previous argument
        local b = w(clink.find_dirs(git_dir..'/refs/remotes/*'))
        :filter(function(remote) return path.is_real_dir(remote) end)
        :reduce({}, function(result, remote)
            return w(path.list_files(git_dir..'/refs/remotes/'..remote, '/*',
                --[[recursive=]]true, --[[reverse_separator=]]true))
            :filter(function(remote_branch)
                return clink.is_match(remote_branch_spec, remote_branch)
            end)
            :concat(result)
        end)

        -- setup display filter to prevent display '+' symbol in completion list
        clink.match_display_filter = function ()
            return b
        end

        return b:map(function(branch)
            return (plus_prefix and '+'..local_branch_spec or local_branch_spec)..':'..branch
        end)
    end
end

local stashes = function(token)  -- luacheck: no unused args

    local git_dir = git.get_git_dir()
    if not git_dir then return w() end

    local stash_file = io.open(git_dir..'/logs/refs/stash')
    -- if there is no stash file, return empty list
    if stash_file == nil then return w() end

    local stashes = {}
    -- make a dictionary of stash time and stash comment to
    -- be able to sort stashes by date/time created
    for stash in stash_file:lines() do
        local stash_time, stash_name = stash:match('(%d%d%d%d%d%d%d%d%d%d) [+-]%d%d%d%d%s+(.*)')
        if (stash_name and stash_name) then
            stashes[stash_time] = stash_name
        end
    end

    stash_file:close()

    -- get times for available stashes into separate table and sort it
    -- from newest to oldest. This is required because of stash@{0}
    -- represents _latest_ stash, not the last one in file
    local stash_times = {}
    for k in pairs(stashes) do
        table.insert(stash_times, k)
    end

    table.sort(stash_times, function (a, b)
        return a > b
    end)

    -- generate matches and match filter table
    local ret = {}
    local ret_filter = {}
    for i,v in ipairs(stash_times) do
        table.insert(ret, "stash@{"..(i-1).."}")
        table.insert(ret_filter, "stash@{"..(i-1).."}    "..stashes[v])
    end

    clink.match_display_filter = function ()
        return ret_filter
    end

    return ret
end

local color_opts = parser({"true", "false", "always"})

local git_options = {
    "core.editor",
    "core.pager",
    "core.excludesfile",
    "core.autocrlf"..parser({"true", "false", "input"}),
    "core.trustctime"..parser({"true", "false"}),
    "core.whitespace"..parser({
        "cr-at-eol",
        "-cr-at-eol",
        "indent-with-non-tab",
        "-indent-with-non-tab",
        "space-before-tab",
        "-space-before-tab",
        "trailing-space",
        "-trailing-space"
    }),
    "commit.template",
    "color.ui"..color_opts, "color.*"..color_opts, "color.branch"..color_opts,
    "color.diff"..color_opts, "color.interactive"..color_opts, "color.status"..color_opts,
    "help.autocorrect",
    "merge.tool", "mergetool.*.cmd", "mergetool.trustExitCode"..parser({"true", "false"}), "diff.external",
    "user.name", "user.email", "user.signingkey",
}

local config_parser = parser(
    "--system", "--global", "--local", "--file"..parser({matchers.files}),
    "--int", "--bool", "--path",
    "-z", "--null",
    "--add",
    "--replace-all",
    "--get", "--get-all", "--get-regexp", "--get-urlmatch",
    "--unset", "--unset-all",
    "--rename-section", "--remove-section",
    "-l", "--list",
    "--get-color", "--get-colorbool",
    "-e", "--edit",
    {git_options}
)

local merge_recursive_options = parser({
    "ours",
    "theirs",
    "renormalize",
    "no-renormalize",
    "diff-algorithm="..parser({
        "patience",
        "minimal",
        "histogram",
        "myers"
    }),
    "patience",
    "ignore-space-change",
    "ignore-all-space",
    "ignore-space-at-eol",
    "rename-threshold=",
    -- "subtree="..parser(),
    "subtree"
})

local merge_strategies = parser({
    "resolve",
    "recursive",
    "ours",
    "octopus",
    "subtree"
})

local git_parser = parser(
    {
        {alias},
        "add" .. parser({matchers.files},
            "-n", "--dry-run",
            "-v", "--verbose",
            "-f", "--force",
            "-i", "--interactive",
            "-p", "--patch",
            "-e", "--edit",
            "-u", "--update",
            "-A", "--all",
            "--no-all",
            "--ignore-removal",
            "--no-ignore-removal",
            "-N", "--intent-to-add",
            "--refresh",
            "--ignore-errors",
            "--ignore-missing"
            ),
        "add--interactive",
        "am",
        "annotate" .. parser({matchers.files},
            "-b",
            "--root",
            "--show-stats",
            "-L",
            "-l",
            "-t",
            "-S",
            "--reverse",
            "-p",
            "--porcelain",
            "--line-porcelain",
            "--incremental",
            "--encoding=",
            "--contents",
            "--date",
            "-M",
            "-C",
            "-h"
            ),
        "apply" .. parser(
            "--stat",
            "--numstat",
            "--summary",
            "--check",
            "--index",
            "--cached",
            "-3", "--3way",
            "--build-fake-ancestor=",
            "-R", "--reverse",
            "--reject",
            "-z",
            "-p",
            "-C",
            "--unidiff-zero",
            "--apply",
            "--no-add",
            "--allow-binary-replacement", "--binary",
            "--exclude=",
            "--include=",
            "--ignore-space-change", "--ignore-whitespace",
            "--whitespace=",
            "--inaccurate-eof",
            "-v", "--verbose",
            "--recount",
            "--directory="
            ),
        "archive",
        "bisect",
        "bisect--helper",
        "blame",
        "branch" .. parser(
            "-v", "--verbose",
            "-q", "--quiet",
            "-t", "--track",
            "--set-upstream",
            "-u", "--set-upstream-to",
            "--unset-upstream",
            "--color",
            "-r", "--remotes",
            "--contains" ,
            "--abbrev",
            "-a", "--all",
            "-d" .. parser({branches}):loop(1),
            "--delete" .. parser({branches}):loop(1),
            "-D" .. parser({branches}):loop(1),
            "-m", "--move",
            "-M",
            "--list",
            "-l", "--create-reflog",
            "--edit-description",
            "-f", "--force",
            "--no-merged",
            "--merged",
            "--column"
        ),
        "bundle",
        "cat-file",
        "check-attr",
        "check-ignore",
        "check-mailmap",
        "check-ref-format",
        "checkout" .. parser({checkout_spec_generator},
            "-q", "--quiet",
            "-b",
            "-B",
            "-l",
            "--detach",
            "-t", "--track",
            "--orphan",
            "-2", "--ours",
            "-3", "--theirs",
            "-f", "--force",
            "-m", "--merge",
            "--overwrite-ignore",
            "--conflict",
            "-p", "--patch",
            "--ignore-skip-worktree-bits"
        ),
        "checkout-index",
        "cherry",
        "cherry-pick"..parser(
            "-e", "--edit",
            "-m", "--mainline ",
            "-n", "--no-commit",
            "-r",
            "-x",
            "--ff",
             "-s", "-S", "--gpg-sign",
            "--allow-empty",
            "--allow-empty-message",
            "--keep-redundant-commits",
            "--strategy"..parser({merge_strategies}),
            "-X"..parser({merge_recursive_options}),
            "--strategy-option"..parser({merge_recursive_options}),
            "--continue",
            "--quit",
            "--abort"
        ),
        "citool",
        "clean",
        "clone" .. parser(
            "--template",
            "-l", "--local",
            "-s", "--shared",
            "--no-hardlinks",
            "-q", "--quiet",
            "-n", "--no-checkout",
            "--bare",
            "--mirror",
            "-o", "--origin",
            "-b", "--branch",
            "-u", "--upload-pack",
            "--reference",
            "--dissociate",
            "--separate-git-dir",
            "--depth",
            "--single-branch", "--no-single-branch",
            "--no-tags",
            "--recurse-submodules", "--shallow-submodules", "--no-shallow-submodules",
            "--jobs"
        ),
        "column",
        "commit" .. parser(
            "-a", "--all",
            "-p", "--patch",
            "-C", "--reuse-message=",
            "-c", "--reedit-message=",
            "--fixup=",
            "--squash=",
            "--reset-author",
            "--short",
            "--branch",
            "--porcelain",
            "--long",
            "-z",
            "--null",
            "-F", "--file=",
            "--author=",
            "--date=",
            "-m", "--message=",
            "-t", "--template=",
            "-s", "--signoff",
            "-n", "--no-verify",
            "--allow-empty",
            "--allow-empty-message",
            "--cleanup", -- .. parser({"strip", "whitespace", "verbatim", "default"}),
            "-e", "--edit",
            "--no-edit",
            "--amend",
            "--no-post-rewrite",
            "-i", "--include",
            "-o", "--only",
            "-u", "--untracked-files", "--untracked-files=", -- .. parser({"no", "normal", "all"}),
            "-v", "--verbose",
            "-q", "--quiet",
            "--dry-run",
            "--status",
            "--no-status",
            "-S", "--gpg-sign", "--gpg-sign=",
            "--"
        ),
        "commit-tree",
        "config"..config_parser,
        "count-objects",
        "credential",
        "credential-store",
        "credential-wincred",
        "daemon",
        "describe",
        "diff" .. parser({local_or_remote_branches, matchers.files}),
        "diff-files",
        "diff-index",
        "diff-tree",
        "difftool"..parser(
            "-d", "--dir-diff",
            "-y", "--no-prompt", "--prompt",
            "-t", "--tool=" -- TODO: complete tool (take from config)
        ),
        "difftool--helper",
        "fast-export",
        "fast-import",
        "fetch" .. parser({remotes},
            "--all",
            "--prune",
            "--tags"
        ),
        "fetch-pack",
        "filter-branch",
        "fmt-merge-msg",
        "for-each-ref",
        "format-patch",
        "fsck",
        "fsck-objects",
        "gc",
        "get-tar-commit-id",
        "grep",
        "gui",
        "gui--askpass",
        "gui--askyesno",
        "gui.tcl",
        "hash-object",
        "help",
        "http-backend",
        "http-fetch",
        "http-push",
        "imap-send",
        "index-pack",
        "init",
        "init-db",
        "log",
        "lost-found",
        "ls-files",
        "ls-remote",
        "ls-tree",
        "mailinfo",
        "mailsplit",
        "merge" .. parser({branches},
            "--commit", "--no-commit",
            "--edit", "-e", "--no-edit",
            "--ff", "--no-ff", "--ff-only",
            "--log", "--no-log",
            "--stat", "-n", "--no-stat",
            "--squash", "--no-squash",
            "-s" .. merge_strategies,
            "--strategy" .. merge_strategies,
            "-X" .. merge_recursive_options,
            "--strategy-option" .. merge_recursive_options,
            "--verify-signatures", "--no-verify-signatures",
            "-q", "--quiet", "-v", "--verbose",
            "--progress", "--no-progress",
            "-S", "--gpg-sign",
            "-m",
            "--rerere-autoupdate", "--no-rerere-autoupdate",
            "--abort"
        ),
        "merge-base",
        "merge-file",
        "merge-index",
        "merge-octopus",
        "merge-one-file",
        "merge-ours",
        "merge-recursive",
        "merge-resolve",
        "merge-subtree",
        "merge-tree",
        "mergetool",
        "mergetool--lib",
        "mktag",
        "mktree",
        "mv",
        "name-rev",
        "notes",
        "p4",
        "pack-objects",
        "pack-redundant",
        "pack-refs",
        "parse-remote",
        "patch-id",
        "peek-remote",
        "prune",
        "prune-packed",
        "pull" .. parser(
            {remotes}, {branches},
            "-q", "--quiet",
            "-v", "--verbose",
            "--recurse-submodules", --[no-]recurse-submodules[=yes|on-demand|no]
            "--no-recurse-submodules",
            "--commit", "--no-commit",
            "-e", "--edit", "--no-edit",
            "--ff", "--no-ff", "--ff-only",
            "--log", "--no-log",
            "--stat", "-n", "--no-stat",
            "--squash", "--no-squash",
            "-s"..merge_strategies,
            "--strategy"..merge_strategies,
            "-X"..merge_recursive_options,
            "--strategy-option"..merge_recursive_options,
            "--verify-signatures", "--no-verify-signatures",
            "--summary", "--no-summary",
            "-r", "--rebase", "--no-rebase",
            "--all",
            "-a", "--append",
            "--depth", "--unshallow", "--update-shallow",
            "-f", "--force",
            "-k", "--keep",
            "--no-tags",
            "-u", "--update-head-ok",
            "--upload-pack",
            "--progress"
        ),
        "push" .. parser(
            {remotes},
            {push_branch_spec},
            "-v", "--verbose",
            "-q", "--quiet",
            "--repo",
            "--all",
            "--mirror",
            "--delete",
            "--tags",
            "-n", "--dry-run",
            "--porcelain",
            "-f", "--force",
            "--force-with-lease",
            "--recurse-submodules",
            "--thin",
            "--receive-pack",
            "--exec",
            "-u", "--set-upstream",
            "--progress",
            "--prune",
            "--no-verify",
            "--follow-tags"
        ),
        "quiltimport",
        "read-tree",
        "rebase" .. parser({local_or_remote_branches}, {branches},
            "-i", "--interactive",
            "--onto" .. parser({branches}),
            "--continue",
            "--abort",
            "--keep-empty",
            "--skip",
            "--edit-todo",
            "-m", "--merge",
            "-s" .. merge_strategies,
            "--strategy"..merge_strategies,
            "-X" .. merge_recursive_options,
            "--strategy-option"..merge_recursive_options,
            "-S", "--gpg-sign",
            "-q", "--quiet",
            "-v", "--verbose",
            "--stat", "-n", "--no-stat",
            "--no-verify", "--verify",
            "-C",
            "-f", "--force-rebase",
            "--fork-point", "--no-fork-point",
            "--ignore-whitespace", "--whitespace",
            "--committer-date-is-author-date", "--ignore-date",
            "-i", "--interactive",
            "-p", "--preserve-merges",
            "-x", "--exec",
            "--root",
            "--autosquash", "--no-autosquash",
            "--autostash", "--no-autostash",
            "--no-ff"
            ),
        "receive-pack",
        "reflog",
        "remote"..parser({
            "add" ..parser(
                "-t"..parser({branches}),
                "-m",
                "-f",
                "--mirror",
                "--tags", "--no-tags"
            ),
            "rename"..parser({remotes}),
            "remove"..parser({remotes}),
            "rm"..parser({remotes}),
            "set-head"..parser({remotes}, {branches},
                "-a", "--auto",
                "-d", "--delete"
            ),
            "set-branches"..parser("--add", {remotes}, {branches}),
            "set-url"..parser(
                "--add"..parser("--push", {remotes}),
                "--delete"..parser("--push", {remotes})
            ),
            "get-url"..parser({remotes}, "--push", "--all"),
            "show"..parser("-n", {remotes}),
            "prune"..parser("-n", "--dry-run", {remotes}),
            "update"..parser({remotes}, "-p", "--prune")
            }, "-v", "--verbose"),
        "remote-ext",
        "remote-fd",
        "remote-ftp",
        "remote-ftps",
        "remote-hg",
        "remote-http",
        "remote-https",
        "remote-testsvn",
        "repack",
        "replace",
        "repo-config",
        "request-pull",
        "rerere",
        -- TODO: Add commit completions
        "reset"..parser({local_or_remote_branches},
            "-q",
            "-p", "--patch",
            "--soft", "--mixed", "--hard",
            "--merge", "--keep"
            ),
        "restore"..parser({matchers.files},
            "-s", "--source",
            "-p", "--patch",
            "-W", "--worktree",
            "-S", "--staged",
            "-q", "--quiet",
            "--progress", "--no-progress",
            "--ours", "--theirs",
            "-m", "--merge",
            "--conflict",
            "--ignore-unmerged",
            "--ignore-skip-worktree-bits",
            "--overlay", "--no-overlay"
        ),
        "rev-list",
        "rev-parse",
        "revert",
        "rm",
        "send-email",
        "send-pack",
        "sh-i18n",
        "sh-i18n--envsubst",
        "sh-setup",
        "shortlog",
        "show",
        "show-branch",
        "show-index",
        "show-ref",
        "stage",
        "stash"..parser({
            "list", -- TODO: The command takes options applicable to the git log
                    -- command to control what is shown and how it's done
            "show"..parser({stashes}),
            "drop"..parser({stashes}, "-q", "--quiet"),
            "pop"..parser({stashes}, "--index", "-q", "--quiet"),
            "apply"..parser({stashes}, "--index", "-q", "--quiet"),
            "branch"..parser({branches}, {stashes}),
            "save"..parser(
                "-p", "--patch",
                "-k", "--no-keep-index", "--keep-index",
                "-q", "--quiet",
                "-u", "--include-untracked",
                "-a", "--all"
                ),
            "clear"
            }),
        "status",
        "stripspace",
        "submodule"..parser({
            "add",
            "init",
            "deinit",
            "foreach",
            "status"..parser("--cached", "--recursive"),
            "summary",
            "sync",
            "update"
        }, '--quiet'),
        "subtree",
        "switch"..parser({local_or_remote_branches},
            "-c", "-C", "--create",
            "--force-create",
            "-d", "--detach",
            "--guess", "--no-guess",
            "-f", "--force", "--discard-changes",
            "-m", "--merge",
            "--conflict",
            "-q", "--quiet",
            "--progress", "--no-progress",
            "-t", "--track",
            "--no-track",
            "--orphan",
            "--ignore-other-worktrees",
            "--recurse-submodules", "--no-recurse-submodules"
        ),
        "svn"..parser({
            "init"..parser("-T", "--trunk", "-t", "--tags", "-b", "--branches", "-s", "--stdlayout",
                "--no-metadata", "--use-svm-props", "--use-svnsync-props", "--rewrite-root",
                "--rewrite-uuid", "--username", "--prefix"..parser({"origin"}), "--ignore-paths",
                "--include-paths", "--no-minimize-url"),
                "fetch"..parser({remotes}, "--localtime", "--parent", "--ignore-paths", "--include-paths",
                "--log-window-size"),
                "clone"..parser("-T", "--trunk", "-t", "--tags", "-b", "--branches", "-s", "--stdlayout",
                "--no-metadata", "--use-svm-props", "--use-svnsync-props", "--rewrite-root",
                "--rewrite-uuid", "--username", "--prefix"..parser({"origin"}), "--ignore-paths",
                "--include-paths", "--no-minimize-url", "--preserve-empty-dirs",
                "--placeholder-filename"),
                "rebase"..parser({local_or_remote_branches}, {branches}),
            "dcommit"..parser("--no-rebase", "--commit-url", "--mergeinfo", "--interactive"),
            "branch"..parser("-m","--message","-t", "--tags", "-d", "--destination",
                             "--username", "--commit-url", "--parents"),
            "log"..parser("-r", "--revision", "-v", "--verbose", "--limit",
                          "--incremental", "--show-commit", "--oneline"),
            "find-rev"..parser("--before", "--after"),
            "reset"..parser("-r", "--revision", "-p", "--parent"),
            "tag",
            "blame",
            "set-tree",
            "create-ignore",
            "show-ignore",
            "mkdirs",
            "commit-diff",
            "info",
            "proplist",
            "propget",
            "show-externals",
            "gc"
        }),
        "symbolic-ref",
        "tag",
        "tar-tree",
        "unpack-file",
        "unpack-objects",
        "update-index",
        "update-ref",
        "update-server-info",
        "upload-archive",
        "upload-pack",
        "var",
        "verify-pack",
        "verify-tag",
        "web--browse",
        "whatchanged",
        "worktree"..parser({
            "add"..parser(
                {matchers.dirs},
                {branches},
                "-f", "--force",
                "--detach",
                "--checkout",
                "--lock",
                "-b"..parser({branches})
            ),
            "list"..parser("--porcelain"),
            "lock"..parser("--reason"),
            "move",
            "prune"..parser(
                "-n", "--dry-run",
                "-v", "--verbose",
                "--expire"
            ),
            "remove"..parser("-f"),
            "unlock"
        }),
        "write-tree",
    },
    "--version",
    "--help",
    "-c",
    "--exec-path",
    "--html-path",
    "--man-path",
    "--info-path",
    "-p", "--paginate", "--no-pager",
    "--no-replace-objects",
    "--bare",
    "--git-dir=",
    "--work-tree=",
    "--namespace="
)

clink.arg.register_parser("git", git_parser)

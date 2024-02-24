require('arghelper')

local function exe_matches_all(word, word_index, line_state, match_builder) -- luacheck: no unused args
    match_builder:addmatch({ match="all", display="\x1b[1mALL" })
    match_builder:addmatch({ match="cmd.exe", display="\x1b[1mCMD.EXE" })
    match_builder:addmatches(clink.filematches(""))
end

local function exe_matches(word, word_index, line_state, match_builder) -- luacheck: no unused args
    match_builder:addmatch({ match="cmd.exe", display="\x1b[1mCMD.EXE" })
    match_builder:addmatches(clink.filematches(""))
end

-- luacheck: no max line length
clink.argmatcher("doskey")
:_addexflags({
    {"/reinstall",  "Installs a new copy of Doskey"},
    {"/macros",     "Display all Doskey macros for the current executable"},
    {"/macros:"..clink.argmatcher():addarg(exe_matches_all), "Display all Doskey macros for the named executable ('ALL' for all executables)"},
    {"/exename="..clink.argmatcher():addarg(exe_matches), "Specifies the executable"},
    {"/macrofile=", "Specifies a file of macros to install"},
})

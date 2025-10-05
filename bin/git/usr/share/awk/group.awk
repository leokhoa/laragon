# group.awk --- functions for dealing with the group file
#
# Arnold Robbins, arnold@skeeve.com, Public Domain
# May 1993
# Revised October 2000
# Revised December 2010

BEGIN {
    # Change to suit your system
    _gr_awklib = "/usr/lib/awk/"
}

function _gr_init(    oldfs, oldrs, olddol0, grcat,
                             using_fw, using_fpat, n, a, i)
{
    if (_gr_inited)
        return

    oldfs = FS
    oldrs = RS
    olddol0 = $0
    using_fw = (PROCINFO["FS"] == "FIELDWIDTHS")
    using_fpat = (PROCINFO["FS"] == "FPAT")
    FS = ":"
    RS = "\n"

    grcat = _gr_awklib "grcat"
    while ((grcat | getline) > 0) {
        if ($1 in _gr_byname)
            _gr_byname[$1] = _gr_byname[$1] "," $4
        else
            _gr_byname[$1] = $0
        if ($3 in _gr_bygid)
            _gr_bygid[$3] = _gr_bygid[$3] "," $4
        else
            _gr_bygid[$3] = $0

        n = split($4, a, "[ \t]*,[ \t]*")
        for (i = 1; i <= n; i++)
            if (a[i] in _gr_groupsbyuser)
                _gr_groupsbyuser[a[i]] = _gr_groupsbyuser[a[i]] " " $1
            else
                _gr_groupsbyuser[a[i]] = $1

        _gr_bycount[++_gr_count] = $0
    }
    close(grcat)
    _gr_count = 0
    _gr_inited++
    FS = oldfs
    if (using_fw)
        FIELDWIDTHS = FIELDWIDTHS
    else if (using_fpat)
        FPAT = FPAT
    RS = oldrs
    $0 = olddol0
}
function getgrnam(group)
{
    _gr_init()
    return _gr_byname[group]
}
function getgrgid(gid)
{
    _gr_init()
    return _gr_bygid[gid]
}
function getgruser(user)
{
    _gr_init()
    return _gr_groupsbyuser[user]
}
function getgrent()
{
    _gr_init()
    if (++_gr_count in _gr_bycount)
        return _gr_bycount[_gr_count]
    return ""
}
function endgrent()
{
    _gr_count = 0
}

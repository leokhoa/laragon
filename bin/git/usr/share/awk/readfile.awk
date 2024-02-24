# readfile.awk --- read an entire file at once
#
# Original idea by Denis Shirokov, cosmogen@gmail.com, April 2013
#

function readfile(file,     tmp, save_rs)
{
    save_rs = RS
    RS = "^$"
    getline tmp < file
    close(file)
    RS = save_rs

    return tmp
}

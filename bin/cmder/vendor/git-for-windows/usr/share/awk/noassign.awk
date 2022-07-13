# noassign.awk --- library file to avoid the need for a
# special option that disables command-line assignments
#
# Arnold Robbins, arnold@skeeve.com, Public Domain
# October 1999

function disable_assigns(argc, argv,    i)
{
    for (i = 1; i < argc; i++)
        if (argv[i] ~ /^[a-zA-Z_][a-zA-Z0-9_]*=.*/)
            argv[i] = ("./" argv[i])
}

BEGIN {
    if (No_command_assign)
        disable_assigns(ARGC, ARGV)
}

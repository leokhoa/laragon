# Set path to perl scriptdirs if they exist
# https://wiki.archlinux.org/index.php/Perl_Policy#Binaries_and_scripts

if status --is-login
    for perldir in /usr/bin/site_perl /usr/bin/vendor_perl /usr/bin/core_perl
        if test -d $perldir
            set PATH $PATH $perldir
        end
    end
end

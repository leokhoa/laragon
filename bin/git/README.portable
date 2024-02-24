README.portable
=======================

This version of Git for Windows is portable, i.e. does not need to
be installed. It will run from any directory you place it in, even
from a USB thumbdrive. It will not write permanent entries into the
Windows registry. It does not need administrator privileges to "install".


Installation
------------

This package is contained in a 7-zip archive with a file name of the form
'PortableGit-<versionstring>.7z.exe'.  It is a self-extracting archive:
you can (double-)click it and it will ask for the desired target directory
(which defaults to C:\Program Files\Git). You may change that as needed or
desired. Your user account needs write access to the selected directory.
(You can move that directory with all its contents to a different place or
computer at any time should you later desire so).

*NOTE*: if you decide to unpack the archive using 7-Zip manually, you must
run the `post-install.bat` script. Git will not run correctly
otherwise.

Functional differences to the non-portable Git for Windows
----------------------------------------------------------

This version does not offer you the convenient right-click context menu
entries "Git GUI Here" and "Git Bash Here", because these would require
to add entries into the Windows registry.


Warning
-------

Since this portable package does not modify any Windows %path%
variables, it is not possible to run the git.exe and gitk.exe files
directly. Start the Git Bash or Git Cmd instead, or add the cmd/ folder
to your %path%.


How to start using PortableGit
------------------------------

If you are comfortable with a Unix-like shell, just launch 'git-bash.exe'.

If not, just launch 'git-cmd.exe'.

Alternatively, you can execute these commands to modify the %path%
variable temporarily:

        set gitdir=c:\portablegit
        set path=%gitdir%\cmd;%path%

Adjust the 'gitdir' according to your setup.  As long as you do not
close the command window, you can now simply type "git" or "gitk" to
really call "c:\portablegit\cmd\git.exe" or "c:\portablegit\cmd\gitk.exe".

By default, git-cmd and git-bash use the directory they were started from as
the working directory when run. You can override this by passing --cd-to-home
to them, which will set the user's home directory as the working directory (as
if Git for Windows was installed).

In addition, if you set the HOME environment variable (either permanently or
for the current session only) you can make Git store and  use the configuration
files in the directory specified in that variable. And if you specify
--cd-to-home, git-bash and git-cmd will use that as the working directory when
launched, too. For example:

        set HOME=%cd%/home
        git --cd-to-home
will use the relative directory named home (%cd% specifies the current
directory).

Quick start
-----------

Start configuring git with your personal settings:
        git config --global user.name "Joe Sixpack"
        git config --global user.email joe.sixpack@g_mail.com

Start using git:
        git --help


How to change %path% permanently
--------------------------------

You may also want to make the modification to the %path% variable a
permanent one. The %path% variable may be changed:

* either on a System level (for all users in the lower pane), if you are
  an Administrator
* or for your own user account only (in the upper pane).

To change the %path% variable permanently:

* right-click "My Computer",
* select "Properties",
* open "Advanced",
* click "Environment Variables",
* highlight the "Path" variable,
* click "Edit" (either in upper or in lower pane),
* add your specific path to front of "Variable value" field, separated
  by a semicolon from the existing entry.


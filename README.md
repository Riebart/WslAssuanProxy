# WslAssuanProxy

A couple quick scripts to proxy gpg from Windows through to both WSL2 and WSL1. WSL2 requires WSL1 due to network abstractions in WSL2.

## Prep

Have this repo cloned into a consistent location in both WSL2 and WSL1, like `~/assuan_proxy`, or something.

Have GnuPG installed in Windows in the PATH for the current user.

## Usage

In WSL1, run `bash assuan.sh`. It'll think, then spawn some sockets, as well as spawn sockets in the WSL environment, then exit.

You can now exit that terminal/shell session!

#!/bin/bash

v1Distro="$1"
v2Distro="$2"

if [ "$v1Distro" == "" ] || [ "$v2Distro" == ""]
then
    v1Distro=$(wsl.exe -l -v | iconv -f utf-16 -t utf-8 | tr -d '\r' | grep "1$" | tail -c+3 | cut -d ' ' -f1)
    v2Distro=$(wsl.exe -l -v | iconv -f utf-16 -t utf-8 | tr -d '\r' | grep "2$" | tail -c+3 | cut -d ' ' -f1)
fi

echo "WSL1 Distro: $v1Distro"
echo "WSL2 Distro: $v2Distro"

ip_a_v1=$(wsl.exe -d "$v1Distro" --cd / ip a & pid="$!"; sleep 1; kill "$pid" 2>/dev/null)
ip_a_v2=$(wsl.exe -d "$v2Distro" --cd / ip a & pid="$!"; sleep 1; kill "$pid" 2>/dev/null)

# The common broadcast indicates a common network CIDR block shared.
# The two distros will have different addresses on the block, but will both be on at least one block.
wslCommonBroadcast=$(comm -12 \
    <(echo "$ip_a_v1" | grep -o "brd [0-9.]*255" | sort) \
    <(echo "$ip_a_v2" | grep -o "brd [0-9.]*255" | sort) | cut -d ' ' -f2)

# The common address we want is the host one, or rather that used by WSL1.
wslCommonAddress=$(wsl.exe -d "$v1Distro" --cd / ip a | grep "$wslCommonBroadcast" | grep -o "inet [0-9.]*" | cut -d ' ' -f2)

echo "WSL2 Common Broadcast: $wslCommonBroadcast"
echo "WSL2 CommonAddress:    $wslCommonAddress"

ls $(wslpath `gpgconf.exe --list-dirs socketdir` | tr -d '\r\n')/S.* |
while read assuanFile
do
    assuanPort=$(head -n1 $assuanFile)
    gpgSocketDir=$(gpgconf --list-dirs socketdir)
    socketName=$(echo "$assuanFile" | sed 's|^.*/\([^/]*\)$|\1|')
    echo $assuanFile:$assuanPort:$socketName

    if `uname -a | grep WSL2 >/dev/null`
    then
        echo "Running in WSL2, not starting the connections to localhost"
    else
        socat tcp-listen:${assuanPort},fork,bind=$wslCommonAddress tcp:127.0.0.1:${assuanPort} &
    fi

    socat \
        unix-listen:${gpgSocketDir}/${socketName},unlink-early,fork \
        "exec:bash assuan_sock.sh ${assuanFile} ${wslCommonAddress}" &
done

#$(gpgconf --list-dirs | grep "`echo "$socket" | sed 's|^.*/\([^/]*\)$|\1|'`$" | cut -d ':' -f2)
#ls /mnt/c/Users/Michael/AppData/Local/gnupg/S.* | while read socket; do echo $socket; socat -x -v unix-listen:$(gpgconf --list-dirs | grep "`echo "$socket" | sed 's|^.*/\([^/]*\)$|\1|'`$" | cut -d ':' -f2),unlink-early,fork "exec:bash ~/.gnupg/assuan.sh ${socket} 172.31.224.1" & done
#bash -c "(tail -n+2 "${assuanFile}"; cat -) | nc -vn "172.31.224.1" `head -n1 "$assuanFile"`

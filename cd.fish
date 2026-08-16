#!/usr/bin/env fish
#
# Plugin: cd_rc (fish port)
# Description: Replaces vanilla cd with a directory-stack-aware cd, custom formatting of the stack, and common directory-change helpers.
# Author: Anon
# Date: 2026
# Version: 1.1

# -- functions
function mkdircd
    if test (count $argv) -eq 0
        return 0
    end

    mkdir -p $argv; and cd -- $argv[-1]
end

function cdUp
    if test (count $argv) -eq 0
        cd ..
        return
    end

    for i in (seq 0 $argv[0])
        cd ..
    end
end

set -g __directory_stack $PWD

function __mypushd
    if builtin cd -- $argv[1]
        set -ga __directory_stack $PWD
        __mydirs
    else
        return 1
    end
end

function __mypopd
    if test (count $__directory_stack) -lt 2
        return 1
    end

    if builtin cd -- $__directory_stack[-2]
        set -e __directory_stack[-1]
        __mydirs
    else
        return 1
    end
end

function __mydirs
    set ln 0
    for d in $__directory_stack[-1..1]
        if test -d "$d"
            set color 36
        else
            set color 31
        end

        printf "\033[1;%sm%2d: \033[m%s\n" $color $ln $d
        set ln (math $ln + 1)
    end
end

# -- wrappers
function cdh
    cd ~
end

function cdu
    cdUp $argv
end

function cd..
    cd ..
end

function cd
    __mypushd $argv
end

function popd
    __mypopd $argv
end

function pop
    __mypopd $argv
end

function dirs
    __mydirs $argv
end

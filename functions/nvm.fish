function nvm --argument-names cmd v --description "Node version manager"
    if test -z "$v" && contains -- "$cmd" install use
        for file in .nvmrc .node-version
            set file (_nvm_find_up $PWD $file) && read v <$file && break
        end
        if test -z "$v"
            echo "nvm: Invalid version or missing \".nvmrc\" file" >&2
            return 1
        end
    end

    switch "$cmd"
        case -v --version
            echo "nvm, version 2.2.5"
        case "" -h --help
            echo "Usage: nvm install <version>    Download and activate the specified Node version"
            echo "       nvm install              Install version from nearest .nvmrc file"
            echo "       nvm use <version>        Activate a version in the current shell"
            echo "       nvm use                  Activate version from nearest .nvmrc file"
            echo "       nvm list                 List installed versions"
            echo "       nvm list-remote          List versions available to install"
            echo "       nvm list-remote <regex>  List versions matching a given regular expression"
            echo "       nvm current              Print the currently-active version"
            echo "       nvm uninstall <version>  Uninstall a version"
            echo "Options:"
            echo "       -v or --version          Print version"
            echo "       -h or --help             Print this help message"
            echo "Variables:"
            echo "       nvm_arch                 Override architecture, e.g. x64-musl"
            echo "       nvm_mirror               Set the Node download mirror"
            echo "       nvm_default_version      Set the default version for new shells"
        case install
            _nvm_index_update $nvm_mirror $nvm_data/.index || return

            string match --entire --regex -- (_nvm_version_match $v) <$nvm_data/.index | read v alias

            if ! set --query v[1]
                echo "nvm: Invalid version number or alias: \"$argv[2..-1]\"" >&2
                return 1
            end

            if test ! -e $nvm_data/$v
                set --local os (command uname -s | string lower)
                set --local ext tar.gz
                set --local arch (command uname -m)

                switch $os
                    case aix
                        set arch ppc64
                    case sunos
                    case linux
                    case darwin
                    case {msys_nt,mingw\*_nt}\*
                        set os win
                        set ext zip
                    case \*
                        echo "nvm: Unsupported operating system: \"$os\"" >&2
                        return 1
                end

                switch $arch
                    case i\*86
                        set arch x86
                    case x86_64
                        set arch x64
                    case arm64
                        string match --regex --quiet "v(?<major>\d+)" $v
                        if test "$os" = darwin -a $major -lt 16
                            set arch x64
                        end
                    case armv6 armv6l
                        set arch armv6l
                    case armv7 armv7l
                        set arch armv7l
                    case armv8 armv8l aarch64
                        set arch arm64
                end

                set --query nvm_arch && set arch $nvm_arch

                set --local dir "node-$v-$os-$arch"
                set --local url $nvm_mirror/$v/$dir.$ext
                test "$os" = win && set --local tmp_exe $TMP/(command date +"%s")-$dir.$ext

                command mkdir -p $nvm_data/$v

                echo -e "Installing Node \x1b[1m$v\x1b[22m $alias"
                echo -e "Fetching \x1b[4m$url\x1b[24m\x1b[7m"
                if test "$os" = win
                    if ! command curl --progress-bar --location $url -o $tmp_exe
                        command rm -rf $nvm_data/$v
                        echo -e "\033[F\33[2K\x1b[0mnvm: Invalid mirror or host unavailable: \"$url\"" >&2
                        return 1
                    end

                    command unzip -qq -o -d $nvm_data/$v $tmp_exe
                    rm -rf $tmp_exe
                else if ! command curl --progress-bar --location $url \
                        | command tar --extract --gzip --directory $nvm_data/$v 2>/dev/null
                    command rm -rf $nvm_data/$v
                    echo -e "\033[F\33[2K\x1b[0mnvm: Invalid mirror or host unavailable: \"$url\"" >&2
                    return 1
                end

                echo -en "\033[F\33[2K\x1b[0m"

                if test "$os" = win
                    command mv $nvm_data/$v/$dir $nvm_data/$v/bin
                else
                    command mv $nvm_data/$v/$dir/* $nvm_data/$v
                    command rm -rf $nvm_data/$v/$dir
                end
            end

            if test $v != "$nvm_current_version"
                set --query nvm_current_version && _nvm_version_deactivate $nvm_current_version
                _nvm_version_activate $v
            end

            printf "Now using Node %s (npm %s) %s\n" (_nvm_node_info)
        case use
            test $v = default && set v $nvm_default_version
            _nvm_list | string match --entire --regex -- (_nvm_version_match $v) | read v __

            if ! set --query v[1]
                echo "nvm: Node version not installed or invalid: \"$argv[2..-1]\"" >&2
                return 1
            end

            if test $v != "$nvm_current_version"
                set --query nvm_current_version && _nvm_version_deactivate $nvm_current_version
                test $v != system && _nvm_version_activate $v
            end

            printf "Now using Node %s (npm %s) %s\n" (_nvm_node_info)
        case uninstall
            if test -z "$v"
                echo "nvm: Not enough arguments for command: \"$cmd\"" >&2
                return 1
            end

            test $v = default && test ! -z "$nvm_default_version" && set v $nvm_default_version

            _nvm_list | string match --entire --regex -- (_nvm_version_match $v) | read v __

            if ! set -q v[1]
                echo "nvm: Node version not installed or invalid: \"$argv[2..-1]\"" >&2
                return 1
            end

            printf "Uninstalling Node %s %s\n" $v (string replace ~ \~ "$nvm_data/$v/bin/node")

            _nvm_version_deactivate $v

            command rm -rf $nvm_data/$v
        case current
            _nvm_current
        case ls list
            _nvm_list | _nvm_list_format (_nvm_current) $argv[2]
        case lsr {ls,list}-remote
            _nvm_index_update $nvm_mirror $nvm_data/.index || return
            _nvm_list | command awk '
                FILENAME == "-" && (is_local[$1] = FNR == NR) { next } {
                    print $0 (is_local[$1] ? " ✓" : "")
                }
            ' - $nvm_data/.index | _nvm_list_format (_nvm_current) $argv[2]
        case \*
            echo "nvm: Unknown command or option: \"$cmd\" (see nvm -h)" >&2
            return 1
    end
end

function _nvm_find_up --argument-names path file
    test -e "$path/$file" && echo $path/$file || begin
        test "$path" != / || return
        _nvm_find_up (command dirname $path) $file
    end
end

function _nvm_version_match --argument-names v
    string replace --regex -- '^v?(\d+|\d+\.\d+)$' 'v$1.' $v |
        string replace --filter --regex -- '^v?(\d+)' 'v$1' |
        string escape --style=regex ||
        string lower '\b'$v'(?:/\w+)?$'
end

function _nvm_list_format --argument-names current regex
    command awk -v current="$current" -v regex="$regex" '
        $0 ~ regex {
            aliases[versions[i++] = $1] = $2 " " $3
            pad = (n = length($1)) > pad ? n : pad
        }
        END {
            if (!i) exit 1
            while (i--)
                printf((current == versions[i] ? " ▶ " : "   ") "%"pad"s %s\n",
                    versions[i], aliases[versions[i]])
        }
    '
end

function _nvm_current
    command --search --quiet node || return
    set --query nvm_current_version && echo $nvm_current_version || echo system
end

function _nvm_node_info
    set --local npm_path (string replace bin/npm-cli.js "" (realpath (command --search npm)))
    test -f $npm_path/package.json || set --local npm_version_default (command npm --version)
    command node --eval "
        console.log(process.version)
        console.log('$npm_version_default' ? '$npm_version_default': require('$npm_path/package.json').version)
        console.log(process.execPath.replace(require('os').homedir(), '~'))
    "
end

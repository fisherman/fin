# nvm.fish

> Node.js version manager lovingly made for [Fish](https://fishshell.com).

Not [_that_](https://github.com/nvm-sh/nvm) POSIX-compatible script. Designed for [Fish](https://fishshell.com), this tool helps you manage multiple active versions of Node on a single local environment. Quickly install and switch between runtimes without cluttering your home directory or breaking system-wide scripts.

- 100% Fish—quick & easy to contribute to or change.
- <kbd>Tab</kbd>-completable seamless shell integration.
- `.node-version` and `.nvmrc` support.
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) compliant.

## Installation

Install with [Fisher](https://github.com/jorgebucaran/fisher):

```console
fisher install jorgebucaran/nvm.fish
```

> **msys2/mingw** users will need to install unzip if not already installed.

## Quickstart

Install the latest Node release and activate it.

```console
nvm install latest
```

Install the latest [LTS](https://github.com/nodejs/Release) (long-term support) Node release.

```console
nvm install lts
```

Install an older LTS release by codename.

```console
nvm install carbon
```

> Installs `8.16.2`, the latest release of the Carbon LTS line.

Or install a specific version of Node.

```console
nvm install v12.9.1
```

> Supports full or partial version numbers, starting with an optional "v".

The `nvm install` command activates the specified Node version only in the current environment. If you want to set the default version for new shells use:

```fish
set --universal nvm_default_version v12.9.1
```

Activate a version you've already installed.

```console
nvm use v14
```

List which versions you have installed (includes your system-installed Node if there is one).

```console
$ nvm list
     system
    v8.17.0 lts/carbon
    v12.9.1
 ▶ v14.15.1 lts/fermium
    v15.3.0 latest
```

Or list all the Node versions available to install.

```console
nvm list-remote
```

Want to uninstall a Node version?

```console
nvm uninstall v12.9.1
```

## `.nvmrc`

An `.nvmrc` file makes it easy to lock a specific version of Node for different projects. Just create an `.nvmrc` (or `.node-version`) file containing a version number or alias, e.g., `latest`, `lts`, `carbon`, in the root of your project.

```console
node --version >.nvmrc
```

Then run `nvm install` to install or `nvm use` to activate that version. Works from anywhere inside your project by traversing the directory hierarchy until an `.nvmrc` is found.

```console
nvm install
```

## Custom Source

If you would like to use a different Node.js mirror that has the same layout as the default at https://nodejs.org/dist, you can set `$nvm_mirror`.
The most common example is users in China can define:

```console
set --universal nvm_mirror https://npm.taobao.org/mirrors/node
```

## License

[MIT](LICENSE.md)
g
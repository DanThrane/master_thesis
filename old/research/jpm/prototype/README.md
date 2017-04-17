# JPM

A package manager for the Jolie language.

## Table of Contents

<!-- MarkdownTOC -->

- [Installation](#installation)
- [Usage](#usage)
    - [Initializing a Project](#initializing-a-project)
    - [Updating and Searching the Package Listing](#updating-and-searching-the-package-listing)
    - [Add and Install Dependencies](#add-and-install-dependencies)
    - [Publishing a Package](#publishing-a-package)

<!-- /MarkdownTOC -->

## Installation

Since JPM uses itself to manage its own dependency, it most be bootstrapped
from an existing version, which includes all dependencies. This can be
retrieved from [here](https://github.com/DanThrane/jpm/releases/download/1.0/jpm.tar.gz).

JPM requires a patched version of the `jolie` executable. The patched version
allows us to load the installed sources, interface files, and libraries. The
patched version is available in `$JPM_HOME/bin/jolie`. On Linux patching can
be done with:

```
cd $JPM_HOME
sudo cp bin/jolie /usr/bin/jolie
```

Executables for JPM are also available in the `bin` folder. The executable is
named `jpm` and should be included in your system path. The executable depends
on the environment variable `JPM_HOME` which should be set to the root of the
installation.

## Usage

### Initializing a Project

A new module can be created using `jpm init`. This will start the project
wizard. Simply fill in the details as needed.

[![asciicast](https://asciinema.org/a/f3rs064kghb3l3n4ubyofo9p4.png)](https://asciinema.org/a/f3rs064kghb3l3n4ubyofo9p4)

### Updating and Searching the Package Listing

Updating the local package database is done via `jpm update`. Packages are
then queried using `jpm search <query>`.

[![asciicast](https://asciinema.org/a/dld943sc50p8aeh04rtg6tvku.png)](https://asciinema.org/a/dld943sc50p8aeh04rtg6tvku)

### Add and Install Dependencies

Dependencies are added in the `module.json` file. They are added in the
dependencies section of the file. Each dependency is of the type:

```json
{
    "module": "module name",
    "version": "1.0.0"
}
```

Dependencies can then be installed using `jpm install`.

[![asciicast](https://asciinema.org/a/2o3mlklnthmidv6rtvvxunr31.png)](https://asciinema.org/a/2o3mlklnthmidv6rtvvxunr31)

### Publishing a Package

Publishing your JPM package is done using the `jpm publish` command. This will
query you for your GitHub credentials. These are needed to create a Pull
Request to the central repository. 

The package being published, must be under version control (Git) and must be
pushed to GitHub.

This will create a PR to the central repository. Once this PR is accepted, the
package will be available on the central repository (remember to `jpm update`).

[![asciicast](https://asciinema.org/a/7zb37urk0fo93sqjjcxo5wmr7.png)](https://asciinema.org/a/7zb37urk0fo93sqjjcxo5wmr7)


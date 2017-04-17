# Existing Work

## Binary Package Managers

|     Name    |       System       |         Purpose          |
|-------------|--------------------|--------------------------|
| Google Play | Android/Chrome OS  | Application distribution |
| App Store   | iOS                | Application distribution |
| APT         | Unix-like          | Software distribution    |
| Steam       | Windows/OS X/Linux | Games distribution       |


## Application-level Package Managers

|   Name   |  Framework/Language | 
|----------|---------------------|
| NPM      | JavaScript (Server) |
| Bower    | JavaScript (Client) |
| Cargo    | Rust                |
| Maven    | JVM                 |
| RubyGems | Ruby                |
| pip      | Python              |

## Bower

|                             |                                                             |
|-----------------------------|-------------------------------------------------------------|
| __Website:__                | [bower.io](http://bower.io)                                 |
| __Source code (Manager):__  | [GitHub: bower/bower](https://github.com/bower/bower)       |
| __Source code (Registry):__ | [GitHub: bower/registry](https://github.com/bower/registry) |
| __Manages:__                | Client-side JavaScript packages                             |
| __Language:__               | JavaScript (Node)                                           |

### Package Convention

Packages are defined in a file called `bower.json`. The specification can be
found [here](https://github.com/bower/spec/blob/master/json.md#name). It can be
created interactively with `bower init`. 
 
The file contains some basic descriptive stuff, such as:

  - `name`
  - `description`
  - `keywords`
  - `authors`
  - `license`

All of these are simply for archiving, and exploration purposes.

Along with several properties which describe the structure of the package:

  - `main`
  - `moduleType`
  - `ignore`

Along with the obvious dependencies properties:

  - `dependencies` 
  - `devDependencies` 

The concept of development dependencies are however interesting, and may help
with package sizes, if certain dependencies aren't needed for the package to
work in a production environment.

And finally there are a few properties which are used as hints to the package
manager:

  - `private`
  - `resolutions`

The `private` property states if the package can be published to the public 
registry.

The `resolutions` property states how dependency conflicts should be resolved
between different packages. Looking into how this is done exactly could be
interesting.

### Package Registration

Package registration is done by using:

```
bower register <package-name> <git-endpoint>
```

There is no user authentication for the public registry, and simply uses a
first-come, first-served policy.

The unregister feature is currently disabled. But before it required GitHub
authentication to validate ownership of the package.

The main-endpoint for the registry (http://bower.herokuapp.com/packages) simply
serves up a large JSON list, which contains names and endpoints for every
package (directly taken from the command).

The registry itself is a very simple node webapp with a Postgres database
backend.

It is possible to run your own private registry.

## NPM

|                            |                                               |
|----------------------------|-----------------------------------------------|
| __Website:__               | [npmjs.com](http://npmjs.com)                 |
| __Source code (Manager):__ | [GitHub: npm/npm](https://github.com/npm/npm) |
| __Manages:__               | Server-side JavaScript packages               |
| __Language:__              | JavaScript (Node)                             |

Do note that NPM has both local packages and global packages. A local NPM
package is a package which belongs to a single application, while a global
package belongs to the system, which NPM is installed on. An example of a global
package would be NPM itself. Command-line tools and other applications would
most often be installed as a global package.

### Package Installation

In NPM packages (or modules) are installed in a folder called `node_modules`. By
default every module is installed directly under this top-level `node_modules`,
however NPM allows several versions of a package to be installed under a single
application. Thus if any of the application's dependencies have internal
dependency conflicts, then NPM will resolve them by nesting the conflicting
versions.

Thus we might have the following modules dependencies of our application:

  - `mod-a@1.0.0`
  	- `mod-d@2.0.0`
  - `mod-b@1.0.0`
    - `mod-d@1.0.0`
  - `mod-c@1.0.0`

This could then result in the following directory structure:

  - `node_modules`
    - `mod-a`
    - `mod-b`
      - `node_modules`
        - `mod-d` (1.0.0)
    - `mod-c`
    - `mod-d` (2.0.0)

Although this depends on the installation order. NPM is non-deterministic when
it comes to the resulting directory structure. See  [this for more information](https://docs.npmjs.com/how-npm-works/npm3-nondet). 
This is most likely only possible due to how tightly connected node and NPM are.
This is also most likely the reason that there is a need for a separate package
manager for the client side (i.e. bower).

However this problematic is resolved by NPM (not sure how, but it sounds like it
is responsible for telling modules where their dependencies are located).

### Package Convention

NPM uses a file called `package.json`. In contains almost the exact same fields
that bower does. This makes sense, given the similar ecosystems, and the fact
that installation and updates of bower is done through npm itself.

However it would seem that NPM has slightly more properties, such as:.

__scripts:__ This property provides a list of scripts to run when certain
lifetime events occur. These include `prepublish`, `publish`, `preinstall`,
`install`, `prestart`, `start`, etc. These would probably all make a lot of
sense for a language like Jolie, since we may configure how certain things are
started with the `start` command. An example provided by the NPM documentation:

```json
{
  "start": "node server.js"
}
```

This would probably translate quite well into how you would want to start a
Jolie service. Although there are certain things we would probably want to
consider. This might make more sense if the package is a "global" one, i.e. a
service we want to run standalone.

An `install` hook might be useful for retrieving API keys etc. 

A prepublish hook could be used for validating state of package, such as running
tests, ensuring a version bump, ensuring changes are written in `CHANGELOG`.

__engines:__ Describes which versions of certain engines (such as "node") are
required to run the package. This would probably also be very useful.
Additionally they also have fields which describe CPU architecture and operating
system. Both blacklist and whitelists are allowed.

### Architecture

The NPM architecture itself is quite interesting and seems to follow a
microservice architecture. Looking at the CLI commands makes it seem like it
exposes a bunch of commands, which other commands themselves are supposed to
call. An example of this would be [npm-cache](https://docs.npmjs.com/cli/cache).

## Cargo

|                            |                                                               |
|----------------------------|---------------------------------------------------------------|
| __Website:__               | [crates.io](http://crates.io)                                 |
| __Source code (Manager):__ | [GitHub: rust-lang/cargo](https://github.com/rust-lang/cargo) |
| __Manages:__               | Rust dependency management, tests and build process           |
| __Language:__              | Rust                                                          |

Cargo, a bit like NPM, differentiates between the type of package being built.
Cargo will want to know if you're building a library or a binary executable.
This kind of concept would probably make a lot of sense for jpm. In this case it
would probably be a service designed for embedding, a service designed for self-
hosting, and a service which is external.

Cargo is directly responsible for running tests and building the
executables/libraries, using the underlying compiler (`rustc`).

Publishing of packages is bound to GitHub, and uses GitHub authroization for
everything. Can't find the exact data, but they most likely download tar balls
directly from GitHub.

Cargo also has the concept of development dependencies.

Cargo also supports features, which can be turned on or off. This is done in the
configuration file, while internally these can be turned on with something like
annotations.
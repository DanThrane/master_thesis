# Provide insight into usage from a tool

It would be nice if the tool(s) that are created allow us to get an insight into
what the package does.

How we provide this insight might be somewhat problematic depending on how we
choose to deliver our packages. But either way, we would probably have to build
some kind of database with introspection into what the packages provide. We
would have to do this staticly, since we otherwise might run into security
issues, i.e. untrusted code run on initialization. 

# How do we deliver packages?

The most obvious choices for delivery of packages would be:

  - JAPs
  - tarballs
  - Something else entirely?

I have a hard time seeing the upside to using JAP files. It will mostly require
a whole lot of work, simply to make them work. At seemingly no gain. Maven
however does use JAR files (which are similar). Although they most likely use
those since they are pre-compiled, contain a manifest, and can have additional
optimization and obfuscation. Jolie being an interpreted language gains nothing
from these things, and the manifest is mostly a problem we could solve using the
package manager. 

For these we should make sure we can support the use-cases we would like:

  - Embedded services (libraries)
  - External services
  - (External self-hosted). The reason I would like this feature is to do
    something along the lines of `npm start` (see [1]) with jolie

[1]: https://docs.npmjs.com/misc/scripts#default-values

## Issues with Include Statements

It would appear that `include` statements, are always relative to the current
working directory. I fear that this will cause problems when developing
packages. More specifically that we may have imports that will work during
development, but will break once packaging has been performed.

## Using JAPs as Package Delivery

Will make it harder to pull information directly from a code repository. This
means that we will most likely have to host the package directly in our
registry. While we can still point to external JAP files, we would most likely
still want to have some self-hosting feature, since these are most likely not
handled "automatically" like in the case of a code repository.

Is semi supported in the current include path, however there are some problems
when we work with:

  - TODO Make a complete list of things that currently do not work
  - TODO If a service require file resources, that are included the JAP, will
    they still work. Or do we get into a case of something working in
    development, but not when bundled inside of a JAP file?

Using JAPs would be easier in the case of drag 'n drop. However this shouldn't
really be an issue, considering that we do not want people to manually copy
files around. We would rather want everyone to use the package manager.

JAP Files shouldn't have name-clashes. 

The current syntax for including a service is rather verbose, for example:

```
include "jar:file:./installed_include/git.jap!include/embed.iol"
```

Instead of:

```
include "git/embed.iol"
```

### Issues

  1. Incorrect search path when embedding a Jolie service within a JAP file. The
     EmbeddedJolieServiceLoader will attempt to load files from the file system,
     as opposed to within the JAP file. See `jap_jolie_embed` for an example.
  2. Expanding on #1. Removing the output port and linking directly to the JAP
     resource works, however the includes from within the `.ol` implementation
     fails to find the interface file within the JAP file. Again it attempts to
     search the file system, as opposed to the JAP file.
  3. The include path convention and the class path convention is broken when
     including from JAP files. This means that the `lib` and `include` folders
     are completely ignored from within a JAP file. This means that we cannot
     package directly on top of this. See `jap_jolie_include`.
  4. Reading file resources from within a JAP file does not work. This could
     give some problems if a service, for example, decides to pull default
     configuration from a file. This would fail since it will be unable to find
     the default file, even though it is located in the JAP file. See 
     `jap_file_reading`.

Regarding issue #1 and #2 gives similar stack-traces which output what is most
likely the current directory. It looks like this: 

```
/home/dan/projects/master_thesis/thoughts/jap_jolie_include/usage/jar:file:./foobar.jap!/foobar.ol
```

Which of course is nonsense path, but this is probably a good hint as to what is
wrong.

## Using (Inflated) Tarballs

Will allow us to easily pull information directly from a Git repository, or for
that matter any other type of version control system.

Makes it easier to get something working under the current version of Jolie. As
we will simply have to add these to the include- and classpaths.

We should be able to avoid name-clashes if we put every tarball into their own
directory. 

### Issues

  1. Relative (to working directory) file paths are problematic. See
     `include_problems`
  2. Files have to be moved around to make it work. This is why I had to create
     the prototype like I did.

# How should the Package Manager aid in Deployment?

The communication ports are rather problematic when we're actually working with
this. We would probably want to separate some of this binding logic to go away.
It should probably be easier to go between either embedding a package or using
an external.

The bigger question is also if we should do this in software (i.e. defining our
own ports) or build support into Jolie or the package manager. Passing
configuration from the package definitions might be a nice way of doing this.
This could work similar to how rust (see [2] or [3]) does this. Could we simply
inject constants into a Jolie program, and then setup the ports with this,
eventually allowing a package to define defaults (for example port numbers). Not
sure what would work best, should probably create some prototypes here.

[2]: http://doc.crates.io/manifest.html#the-metadata-table-optional
[3]: http://doc.crates.io/manifest.html#the-features-section

# How do we Host Packages?

As a core requirement we would probably want users to be able to create their
own private registry. This means that we should build the entire application
around this requirement. This would probably mean that the registry should be
easy to self-host. This should probably include all of the same features as the
public, such as a web-interface. Ideally the registry should be installable as a
package itself.

On top of this there is the question of self-hosting or using external hosting.
Which also brings in a question of security (i.e. how do we validate the
integrity of a package. This will most likely be done using some kind of
checksum). Requiring externally hosted Git repositories would probably be the
easiest thing to do, and wouldn't be a huge limitation. To support private
registries then the client will need to do authentication.

If we use git repositories, then it will probably be prolematic to use JAP files
as a means of distributing.
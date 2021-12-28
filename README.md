# NahaJuliaRegistry

This repository provides a Julia registry for my Julia projects.

## About

This repository also includes the code I used to build this registry.
Those tools include:

- code to identify which of my github repositories contain Julia packages

- code to make an empty registry

- code to identify the tag with the latest SemVer version.  If you make use of branches or other reference types you may need to mosify `ACCEPTABLE_OBJECT_TYPES` and related code.

- create a staging directopry in which to extract clean clones of my projects.  For some reason, LocalRegistry requires clean local copies.

- some glue code infront of `LocalRegistry.register`.


These tools make use of these other Julia packages:

- UUIDs to allocate a UUID for the new registry

- GitHub to list all of my Github repositories, identify which are Julia packages, and extract clean local clones of my package repositories

- TOML to parse the Project.toml files read from Github

- RegistryTools to create an empty Registry.toml file

- LocalRegistry to fill in the registry.


## Why

Here follows a rant about what led me to do this and my various
ovservations and frustrations about the Julia
environment/package/registry ecosystem.


I have several unpublished packages whose usage models depend on
Pluto.  These packages provide library utilities for designing or
planning woodworking projects.  Each such design is developed in its
own Pluto notebook.  I would like to be able to access these notebooks
over the internet, from my smartphone through
[Binder](https://mybinder.org/).
Therefore, all resources that a notebook might require must be
available from GitHub, not a local file system.

Among my unpublished packages are a cloned version of `NativeSVG.jl` for
which I have a pending PR.  This is an issue because my code depends
on these changes to `NativeSVG`.  I've added a pre-release designator
to the version spec of my `NativeSVG` clone to distinguish it from
that of the original author, but the code that parses the `compat`
section of a `Project.toml` file doesn't understand prerelease
designators in SemVer specs. See
[this issue)[https://github.com/JuliaLang/Pkg.jl/issues/2789).

Just constructing a temporary workspace/environment containing the
packages my notebooks need takes several minutes each time I open one
of these notebooks.

*FEATURE REQUEST:* I wish that `Pkg.activate` could take a URL where
it would look for the `Project.toml` and `Manifest.toml` files of a
workspace.  I'd be content for it to throw an error if any operation
tried to modify the workspace.

Newer versions of Pluto allow for a workspace to be embedded in a
Pluto notebook so long as that workspace only referrs to registered
packages.  It was suggested that I could construct a private registry
and that the Pluto package manager could use it.

I'm trying to use `LocalRegistry` as some have suggested.  It seems to
require a clean local checkout of each project that I want to
register.  I don't understand why it needs a clean local copy, what
modifications it might make to my projects, nor do I see that
documented anywhere.  I figured I could try it on one project and see
what happens though.

It turnes out none of my local clones were modified by `LocalRegistry`.

At this point I should point out that many of my projects
under`.julia/dev` are under active development and those repositories
are not clean.  This is why this repository includes code to grab
clean clones from GitHub.

It is not clear to me if `Pkg.develop` does anything more than `git
clone`.  It's doc string says:

> Make a package available for development by tracking it by path. If pkg is given with only a name or by a URL, the package will be downloaded to the location specified by the environment variable JULIA_PKG_DEVDIR, with .julia/dev as the default.

but there is no explanation of what "tracking it by path" means.

Though error messages in `LocalRegistry` instruct one to use
`Pkg.develop`, `git clone` is sufficient.

```
Pkg.Registry.add(RegistrySpec(; url="https://github.com/MarkNahabedian/NahaJuliaRegistry.git"))
```

succeeds.  I can `using` my projects without haivinig to `Pkg.add` them first.


# deopkg

A [PackageKit](https://github.com/PackageKit/PackageKit) plugin for [Solus](https://getsol.us)
encapsulating the `eopkg` package manager. This effort exists to assist in decoupling Solus from
`python2` and unlocking the path towards Serpent based tooling.

eopkg carries a lot of legacy from its predecessor, PiSi, such as Python2, piksimel, etc. Basic
operations such as enumeration of the available candidates via `PackageDB` take approximately
5-10s to complete, leaking approx. 300MiB per iteration in our tests.

The `deopkg` plugin aims to bridge the gap by alleviating performance and stability issues, whilst
allowing Solus to put `eopkg` into a sealed unit.

### Technical notes

This plugin is implemented in D Lang, exposing a C ABI via [packagekit-d](https://github.com/packagekit-d).
All Pythonic calls are implemented directly in `libpython2.7` using the [pyd](https://github.com/ariovistus/pyd) embedded module.

Due to the extreme overhead of interacting with the PiSi internals, a simplified RPC model is employed:

 - A `socketpair` is constructed
 - Caller invokes `fork()` `wait()` via `runForked` helper API
 - Fork child initialises `libpython2.7`, runs Pythonic functions, and **yields** via Generator.
 - Fork child serializes all results over `socket` (currently using [asdf](http://asdf.libmir.org/))
 - Main process pulls artefacts from `socket` and handles, using `@nogc` strategy where needed.

Each "fat" operation is handled, automatically, via this forking architecture. Once the operation has completed,
the fork child is disposed of and memory is returned immediately to the kernel. Optimisations are made within `packagekit-d`
and this project to minimise any use of a garbage collector and ensure minimal footprint over time.

Note that caching is employed for package lists using an `sqlite3` database to minimise the lookup cost for `resolve` and `get-packages`.

As a final note, this plugin is an *out of tree* plugin build for PackageKit. Unfortunately for C projects, PackageKit has been designed for
all backend modules to be built *in tree*. For `packagekit-d`, we simply encapsulate the minimal `extern(C)` interface in idiomatic D wrappers
and rely on `@weak` symbol linkage that will resolve when PackageKit calls `dlopen()` on `libpk_backend_deopkg.so`.

### Testing

Build the plugin using `dub`. If available, you should enable `sse4.2` for SIMD optimisations in asdf for the IPC mechanism.

```bash
$ DFLAGS="-mcpu=native -O3 -mattr=+sse4.2 -release" dub build -f
```

The `.so` should then be dropped (or linked, when testing) into the PackageKit module directory:

    /usr/lib64/packagekit-backend/libpk_backend_deopkg.so
    
Finally, run `packagekitd`:

    $ sudo /usr/libexec/packagekitd -v

Verify that the `deopkg` plugin is being used.

```bash
$ pkcon backend-details                                                      ─╯
Name:		deopkg
Description:	eopkg support
Author:	Serpent OS Developers
```
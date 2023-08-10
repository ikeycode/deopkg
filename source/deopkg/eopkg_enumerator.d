/*
 * SPDX-FileCopyrightText: Copyright © 2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * deopkg.eopkg_enumerator
 *
 * Access `eopkg` packages via InstallDB/PackageDB for enumeration
 *
 * Authors: Copyright © 2023 Serpent OS Developers
 * License: Zlib
 */

module deopkg.eopkg_enumerator;

@safe:

import std.stdint : uint64_t;
import pyd.pyd;
import pyd.embedded;
import packagekit.walkietalkie;
import packagekit.forkworker;
import std.algorithm : map, joiner;
import asdf;

public alias Release = uint64_t;

/** 
 * Map a repository
 */
public struct EopkgRepo
{
    /** 
     * Public repo name (ID)
     */
    string name;

    /** 
     * Remote URI
     */
    string uri;

    /** 
     * Enabled?
     */
    bool enabled;

    // dfmt off
    static alias PyWrapped = wrap_struct!(
        EopkgRepo,
        ModuleName!"deopkg",
        Member!("name", Mode!"rw"),
        Member!("uri", Mode!"rw"),
        Member!("enabled", Mode!"rw")
    );
    // dfmt on
}

/** 
 * Encapsulation of an eopkg Package in as much detail as we care about.
 * As and when new fields are needed, we add them.
 */
public struct EopkgPackage
{
    /** 
     * Unique package identifier, in the `PkPackage` internal format:
     * `$name;$version-$rel;$architecture;$origin`
     */
    string pkgID;

    /** 
     * Stable package name (indexed)
     */
    string name;

    /**
     * Version identifier
     */
    string version_;

    /**
     * Numerical source ID
     */
    Release release;

    /**
     * Brief summary to describe the package
     */
    string summary;

    /**
     * Full description of the software
     */
    string description;

    /**
     * Upstream homepage
     */
    string homepage;

    /** 
     * Is the package installed?
     */
    bool installed;

    // dfmt off
    static alias PyWrapped = wrap_struct!(
        EopkgPackage,
        ModuleName!"deopkg",
        Member!("pkgID", Mode!"rw"),
        Member!("name", Mode!"rw"),
        Member!("version_", PyName!"version", Mode!"rw"),
        Member!("release", Mode!"rw"),
        Member!("summary", Mode!"rw"),
        Member!("description", Mode!"rw"),
        Member!("homepage", Mode!"rw"),
        Member!("installed", Mode!"rw"),
    );
}

/** 
 * Force enumerator mode for the eopkg API calls
 */
enum EopkgMode
{
    packages,
    repos,
}

/** 
 * The EopkgEnumerator encapsulates the pythonic internals of eopkg and
 * allows us to return a set of eopkg objects.
 *
 * Thanks to the nature of eopkg/pisi, and python2, these calls are incredibly
 * leaky and slow! To mitigate this we perform the calls under ForkWorker and
 * serialise back to the enumerator using a WalkieTalkie (`socketpair`).
 */
public struct EopkgEnumerator(EopkgMode Mode)
{
    static if (Mode == EopkgMode.packages)
    {
        private enum pythonFile = "getPackages.py";
        alias EnumType = EopkgPackage;
    } else static if (Mode == EopkgMode.repos)
    {
        private enum pythonFile = "getRepos.py";
        alias EnumType = EopkgRepo;
    }

    /** 
     * Communicate with python files
     *
     * Returns: Exit code indicating success
     */
    private static int enumRunner(ref WalkieTalkie comms) @trusted
    {
        // add the eopkg module
        on_py_init({ add_module!(ModuleName!"deopkg"); });
        py_init();
        static if (Mode == EopkgMode.packages)
        {
            EopkgPackage.PyWrapped();
        } else static if (Mode == EopkgMode.repos)
        {
            EopkgRepo.PyWrapped();
        }

        // Serialize all EopkgPackage from getPackages into asdf return
        auto serial = jsonSerializer(&comms.write);
        alias enumeratorFunction = py_def!(import(pythonFile), "deopkg",
                PydInputRange!EnumType function());
        serial.serializeValue(enumeratorFunction);
        serial.flush();
        comms.stop();
        return 0;
    }

    /** 
     * Returns: A range over all packages
     */
    auto opSlice() @trusted
    {
        auto comms = walkieTalkie();
        const child = runForked(&enumRunner, comms);

        return comms.reader
            .parseJsonByLine
            .map!(o => o.byElement)
            .joiner
            .map!(e => e.deserialize!EnumType);
    }
}

/** 
 * Convenience function: Create new eopkgEnumerator
 *
 * Params:
 *  mode = Style of enumerator we need
 */
auto eopkgEnumerator(EopkgMode mode = EopkgMode.packages)() @trusted => EopkgEnumerator!mode();

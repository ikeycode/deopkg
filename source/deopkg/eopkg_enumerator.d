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

public alias Release = uint64_t;

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
}

/** 
 * The EopkgEnumerator encapsulates the pythonic internals of eopkg and
 * allows us to return a set of EopkgPackage objects.
 *
 * Thanks to the nature of eopkg/pisi, and python2, these calls are incredibly
 * leaky and slow! To mitigate this we perform the calls under ForkWorker and
 * serialise back to the enumerator using a WalkieTalkie (`socketpair`).
 */
public struct EopkgEnumerator
{
    @disable this();
    @disable this(this);
}

/*
 * SPDX-FileCopyrightText: Copyright © 2023 Ikey Doherty
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * deopkg
 *
 * Main portions of deopkg
 *
 * Authors: Copyright © 2023 Ikey Doherty
 * License: Zlib
 */

module deopkg;

@safe:

import packagekit.plugin;
import pyd.pyd;
import pyd.embedded;
import std.stdio : writeln;
import std.experimental.logger;

/**
 * Initialise python
 */
shared static this() @trusted
{
    info("Initialising python");
    py_init();
}

/**
 * Kill python
 */
shared static ~this() @trusted
{
    info("Shutting down python");
    py_finish();
}

/** 
 * Hook up the packagekit plugin with our own system
 *
 * Returns: A new PackageKit plugin
 */
export extern (C) Plugin packagekit_d_plugin_create()
{
    return new EopkgPlugin();
}

/** 
 * Implement (d)eopkg support for PackageKit
 */
public final class EopkgPlugin : Plugin
{
    /** 
     * Construct a new eopkg plugin
     */
    this()
    {
        super("deopkg", "eopkg support", "Serpent OS Developers", [
            "application/x-solus-package"
        ]);
    }
}

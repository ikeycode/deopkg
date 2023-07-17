/*
 * SPDX-FileCopyrightText: Copyright © 2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * deopkg.pk_plugin
 *
 * Provides a PackageKit backend
 *
 * Authors: Copyright © 2023 Serpent OS Developers
 * License: Zlib
 */

module deopkg.pk_plugin;

@safe:

import packagekit.plugin;
import pyd.pyd;
import pyd.embedded;
import std.stdio : writeln;
import std.experimental.logger;

import packagekit.pkg;

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

    override void listPackages(PkBackendJob* job, SafeBitField!PkFilterEnum filters) @trusted
    {
        // TODO: Require ID upfront.
        auto pkg = Package.create();
        pkg.id = "firefox;115.0.2-220;x86_64;fake";
        pkg.summary = "I am a fakebackend";
        // TODO: Fix enum names!
        pkg.info = PkInfoEnum.PK_INFO_ENUM_AVAILABLE;
        auto list = PackageList.create(1);
        list ~= pkg;

        // TODO: Unfudge this api!
        job.pk_backend_job_packages(list.pointer);
    }
}

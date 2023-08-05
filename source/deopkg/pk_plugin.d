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
import packagekit.pkg;
import packagekit.walkietalkie;
import packagekit.forkworker;

import asdf;
import std.algorithm : map, joiner;
import pyd.pyd;
import pyd.embedded;
import std.string : format;
import std.array : array;

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
 * Basic eopkg
 */
struct EopkgPackage
{
    string pkgID;
    string name;
    string version_;
    string summary;
}

/**
 * Convenience wrapper to find all packages
 */
static int enumerator(ref WalkieTalkie comms) @trusted
{
    // add the eopkg module
    on_py_init({ add_module!(ModuleName!"deopkg"); });
    py_init();

    // Wrap EopkgPackage as a usable type (deopkg.EopkgPackage)
    wrap_struct!(EopkgPackage, ModuleName!"deopkg", Member!("pkgID",
            Mode!"rw"), Member!("name", Mode!"rw"), Member!("version_",
            PyName!"version", Mode!"rw"), Member!("summary", Mode!"rw"),)();

    // Serialize all EopkgPackage from getPackages into asdf return
    auto serial = jsonSerializer(&comms.write);
    alias getPackages = py_def!(import("getPackages.py"), "deopkg",
            PydInputRange!EopkgPackage function());
    auto packages = getPackages().array;
    serial.serializeValue(packages);
    serial.flush();
    comms.stop();
    return 0;
}

/**
 * FIXME: Use cleaner code!
 */
static PackageList test_enumeration() @trusted
{
    PackageList pl = PackageList.create();
    auto comms = walkieTalkie();
    auto child = runForked(&enumerator, comms);
    imported!"std.stdio".writeln("awaiting ppkg");
    foreach (pkg; comms.reader.parseJsonByLine.map!(o => o.byElement).joiner)
    {
        EopkgPackage ppkg = pkg.deserialize!EopkgPackage;
        auto npkg = Package.create();
        npkg.id = ppkg.pkgID;
        npkg.summary = ppkg.summary;
        npkg.info = PkInfoEnum.PK_INFO_ENUM_AVAILABLE;
        pl ~= npkg;
    }
    child.wait;
    return pl;
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
        auto enu = test_enumeration();
        // TODO: Unfudge this api!
        job.pk_backend_job_packages(enu.pointer);
    }
}

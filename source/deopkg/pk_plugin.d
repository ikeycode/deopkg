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
 * FIXME: Use cleaner code!!
 */
static int enumerator(ref WalkieTalkie comms) @trusted
{
    py_init();
    auto ctx = new InterpContext();

    ctx.pisi = py_import("pisi");
    ctx.pdb = ctx.py_eval("pisi.db.packagedb.PackageDB()");
    auto availablePkgs = ctx.py_eval("[pdb.get_package_repo(x) for x in pdb.list_packages(None)]");

    auto serial = jsonSerializer(&comms.write);
    EopkgPackage[] pkgs;

    foreach (returnedTuple; availablePkgs)
    {
        auto availablePkg = returnedTuple[0];
        auto repo = returnedTuple[1].to_d!string;
        auto name = availablePkg.name.to_d!string;
        auto vers = availablePkg.getattr("version").to_d!string;
        auto rel = availablePkg.release.to_d!string;
        auto arch = availablePkg.architecture.to_d!string;
        auto summary = availablePkg.summary.to_d!string;

        EopkgPackage tmp = {
            format!"%s;%s-%s;%s;%s"(name, vers, rel, arch, repo), name, vers, summary,
        };
        pkgs ~= tmp;
    }
    imported!"std.stdio".writeln("sending");
    serial.serializeValue(pkgs);
    imported!"std.stdio".writeln("done");
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

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

import deopkg.eopkg_enumerator;
import std.algorithm : map, each;

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
        PackageList pl = PackageList.create();
        eopkgEnumerator[].map!((eopkg) {
            auto pkg = Package.create();
            pkg.id = eopkg.pkgID;
            pkg.summary = eopkg.summary;
            pkg.info = PkInfoEnum.PK_INFO_ENUM_AVAILABLE;
            return pkg;
        }).each!(p => pl ~= p);
        // TODO: Unfudge this api!
        job.pk_backend_job_packages(pl.pointer);
    }
}

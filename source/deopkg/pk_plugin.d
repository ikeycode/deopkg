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
import std.algorithm : filter, map, each;
import deopkg.eopkg_cache;
import mir.parse;

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

    override void initialize()
    {
        cache = new EopkgCache();
        // TODO: Don't do this on every startup.
        cache.refresh();
    }

    override void listPackages(scope ref BackendJob job, SafeBitField!PkFilterEnum filters)
    {
        PackageList pl = PackageList.create();
        () @trusted {
            cache.list
                .filter!((eopkg) {
                    if (filters.contains(PkFilterEnum.PK_FILTER_ENUM_NOT_INSTALLED)
                        && eopkg.installed)
                    {
                        return false;
                    }
                    if (filters.contains(PkFilterEnum.PK_FILTER_ENUM_INSTALLED) && !eopkg.installed)
                    {
                        return false;
                    }
                    return true;
                })
                .map!((eopkg) {
                    auto pkg = Package.create();
                    pkg.id = eopkg.pkgID;
                    pkg.summary = eopkg.summary;
                    if (eopkg.installed)
                    {
                        pkg.info = PkInfoEnum.PK_INFO_ENUM_INSTALLED;
                    }
                    else
                    {
                        pkg.info = PkInfoEnum.PK_INFO_ENUM_AVAILABLE;
                    }
                    return pkg;
                })
                .each!(p => pl ~= p);
        }();
        job.addPackages(pl);
    }

    /* List eopkg repos with their URI as the description */
    override void listRepos(scope ref BackendJob job, SafeBitField!PkFilterEnum filters) @trusted
    {
        foreach (repo; eopkgEnumerator!(EopkgMode.repos))
        {
            job.addRepo(repo.name, repo.uri, repo.enabled);
        }
    }

    /* Resolve a package */
    override void resolve(scope ref BackendJob job, SafeBitField!PkFilterEnum, const char*[] pkgIDs) @trusted
    {
        import std.string : fromStringz;

        PackageList pl = PackageList.create();

        foreach (id; pkgIDs)
        {
            auto dID = id.fromStringz;
            foreach (eopkg; cache.byName(dID))
            {
                auto pkg = Package.create();
                pkg.id = eopkg.pkgID;
                pkg.summary = eopkg.summary;
                pkg.info = eopkg.installed ? PkInfoEnum.PK_INFO_ENUM_INSTALLED
                    : PkInfoEnum.PK_INFO_ENUM_AVAILABLE;
                pl ~= pkg;
            }
        }

        job.addPackages(pl);
    }

private:

    EopkgCache cache;
}

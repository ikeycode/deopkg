/*
 * SPDX-FileCopyrightText: Copyright © 2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * deopkg.metadata
 *
 * Encapsulates eopkg metadata
 *
 * Authors: Copyright © 2023 Serpent OS Developers
 * License: Zlib
 */

module deopkg.metadata;

@safe:

import pyd.pyd;
import pyd.pydobject;
import std.conv : to;

public struct Update
{
    string release;
    string date;
    string version_;
    string comment;
    string name;
    string email;

    /** 
     * Create an update from an Update object
     *
     * Params:
     *   obj = The input object
     * Returns: Update
     */
    static Update from(scope PydObject obj) @trusted
    {
        Update u = {
            release: obj.release.to_d!string, date: obj.date.to_d!string,
            version_: obj.getattr("version").to_d!string, comment: obj.getattr("comment")
                    .to_d!string, name: obj.name.to_d!string, email: obj.email.to_d!string,
        };
        return u;
    }
}

public struct Source
{
    string name;
    string homepage;
    string packager;

    /** 
     * Construct Source from python object
     *
     * Params:
     *   obj = The input object
     * Returns: Source
     */
    static Source from(scope PydObject obj) @trusted
    {
        Source s = {
            name: obj.name.to_d!string, homepage: obj.homepage.to_d!string,
            packager: obj.packager.to_d!string,
        };
        return s;
    }
}

public struct Package
{
    string build;
    string buildHost;
    string distribution;
    string distributionRelease;
    string architecture;
    string installedSize;
    string packageSize;
    string packageHash;
    string packageURI;
    string packageFormat;

    Source source;
    Update[] history;

    static Package from(scope PydObject obj) @trusted
    {
        Package p = {
            build: obj.hasattr("build") ? obj.build.to_d!string : null, buildHost: obj.buildHost.to_d!string,
            distribution: obj.distribution.to_d!string,
            distributionRelease: obj.distributionRelease.to_d!string, architecture: obj.architecture.to_d!string,
            installedSize: obj.architecture.to_d!string, packageFormat: obj.packageFormat.to_d!string,
        };

        if (obj.hasattr("packageHash"))
        {
            p.packageHash = obj.packageHash.to_d!string;
        }
        if (obj.hasattr("packageURI"))
        {
            p.packageURI = obj.packageURI.to_d!string;
        }
        if (obj.hasattr("packageSize"))
        {
            p.packageSize = obj.packageSize.to_d!string;
        }
        if (obj.hasattr("history"))
        {
            foreach (up; obj.history)
            {
                p.history ~= Update.from(up);
            }
        }
        if (obj.hasattr("source"))
        {
            p.source = Source.from(obj.source);
        }

        return p;
    }
}

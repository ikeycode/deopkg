/*
 * SPDX-FileCopyrightText: Copyright © 2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * deopkg.eopkg_cache
 *
 * Cache Eopkg internals for faster subsequent usage
 *
 * Authors: Copyright © 2023 Serpent OS Developers
 * License: Zlib
 */

module deopkg.eopkg_cache;

@safe:

import etc.c.sqlite3;
import std.exception : enforce;
import std.string : fromStringz;
import deopkg.eopkg_enumerator;

/** 
 * Our EopkgCache simply wraps the internal DBs into something that is quicker to access
 * than what is available in PiSi/eopkg - giving quicker resolve / list times.
 * The schema is not stable, and on refresh we destroy the DB cache.
 */
public final class EopkgCache
{

    /** 
     * Construct a new EopkgCache with the global directory (PackageKit)
     */
    this()
    {
        auto code = () @trusted {
            return sqlite3_open("/var/lib/PackageKit/deopkg.db", &db);
        }();
        enforce(code == 0);

        // prepared statement to bind package imports
        code = () @trusted {
            static immutable char[] zsql = import("importPkg.sql");
            return sqlite3_prepare_v2(db, zsql.ptr, zsql.length, &stmt, null);
        }();
        enforce(code == 0);
    }

    /** 
     * Terminate underlying connections
     */
    void close() @trusted
    {
        if (db !is null)
        {
            sqlite3_finalize(stmt);
            sqlite3_close(db);
            db = null;
        }
    }

    /** 
     * Refresh the db
     */
    void refresh() @trusted
    {
        import core.stdc.stdio : puts, printf;

        puts(" -> begin enumerate");
        ulong nPkgs;
        scope (exit)
            printf(" -> end enumerate, %d packages found. Resume normal startup\n", nPkgs);

        rebuildSchema();
        foreach (pkg; eopkgEnumerator[])
        {
            if (!pkg.installed)
                nPkgs += 1;
        }
    }

private:

    /** 
     * Instruct SQLite to rebuild our DB schema (Disposable)
     */
    void rebuildSchema() @trusted
    {
        char* errorMsg;
        scope (exit)
        {
            if (errorMsg !is null)
                sqlite3_free(errorMsg);
        }

        const rc = sqlite3_exec(db, import("init.sql"), null, null, &errorMsg);
        enforce(rc == 0, errorMsg.fromStringz);
    }

    sqlite3* db;
    sqlite3_stmt* stmt;
}

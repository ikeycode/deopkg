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
import std.traits : isNumeric;

// TODO: Check any of this works!
pragma(inline, true) static void bindText(sqlite3_stmt* stmt, ref int index, ref string str) @trusted
{
    auto rc = sqlite3_bind_text(stmt, ++index, str.ptr, cast(int) str.length, null);
    enforce(rc == SQLITE_OK);
}

pragma(inline, true) static void bindInt(I)(sqlite3_stmt* stmt, ref int index, ref I datum) @trusted
        if (isNumeric!I)
{
    const rc = sqlite3_bind_int(stmt, ++index, cast(int) datum);
    enforce(rc == SQLITE_OK);
}

pragma(inline, true) static void beginTransaction(sqlite3* db) @trusted
{
    const rc = sqlite3_exec(db, "BEGIN TRANSACTION;", null, null, null);
    enforce(rc == SQLITE_OK);
}

pragma(inline, true) static void endTransaction(sqlite3* db) @trusted
{
    const rc = sqlite3_exec(db, "COMMIT;", null, null, null);
    enforce(rc == SQLITE_OK);
}

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
        import std.datetime.stopwatch : StopWatch, AutoStart;

        auto stp = StopWatch(AutoStart.yes);
        import std.stdio : writeln;

        puts(" -> begin enumerate");
        ulong nPkgs;
        scope (exit)
            printf(" -> end enumerate, %d packages found. Resume normal startup\n", cast(int) nPkgs);

        rebuildSchema();
        db.beginTransaction();
        scope (exit)
            db.endTransaction();

        foreach (pkg; eopkgEnumerator[])
        {
            int index = 0;
            ++nPkgs;
            sqlite3_reset(stmt);
            stmt.bindText(index, pkg.pkgID);
            stmt.bindText(index, pkg.name);
            stmt.bindText(index, pkg.version_);
            stmt.bindInt(++index, pkg.release);
            stmt.bindText(index, pkg.summary);
            stmt.bindText(index, pkg.description);
            const rc = sqlite3_step(stmt);
            enforce(rc == SQLITE_DONE);
        }
        stp.stop();
        writeln(stp.peek);
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

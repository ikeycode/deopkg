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
import std.traits : isNumeric, isSomeString, isBoolean;
import mir.parse;

pragma(inline, true) static void bindText(S)(sqlite3_stmt* stmt, int index, ref S str) @trusted
        if (isSomeString!S)
{
    enforce(sqlite3_bind_text(stmt, index, str.ptr, cast(int) str.length, null) == SQLITE_OK);
}

pragma(inline, true) static void bindInt(I)(sqlite3_stmt* stmt, int index, ref I datum) @trusted
        if (isNumeric!I || isBoolean!I)
{
    const rc = sqlite3_bind_int(stmt, index, cast(int) datum);
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

private struct StatementEnumerator
{
    sqlite3_stmt* query;

    EopkgPackage front()
    {
        return head;
    }

    void popFront() @trusted
    {
        ret = sqlite3_step(query);
        if (ret != SQLITE_ROW)
            return;

        head = EopkgPackage.init;
        head.pkgID = cast(string) sqlite3_column_text(query, 0).fromStringz;
        head.name = cast(string) sqlite3_column_text(query, 1).fromStringz;
        head.version_ = cast(string) sqlite3_column_text(query, 2).fromStringz;
        head.release = sqlite3_column_int(query, 3);
        head.homepage = cast(string) sqlite3_column_text(query, 4).fromStringz;
        head.summary = cast(string) sqlite3_column_text(query, 5).fromStringz;
        head.description = cast(string) sqlite3_column_text(query, 6).fromStringz;
        head.installed = cast(bool) sqlite3_column_int(query, 7);
    }

    bool empty()
    {
        return ret == SQLITE_DONE || ret == SQLITE_ERROR;
    }

    ref auto prime() return
    {
        popFront();
        return this;
    }

    int ret;
    EopkgPackage head;
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
        enforce(code == SQLITE_OK);

        // DROPS :O
        rebuildSchema();

        // prepared statement to bind package imports
        code = () @trusted {
            static immutable char[] zsql = import("importPkg.sql");
            return sqlite3_prepare_v2(db, zsql.ptr, zsql.length, &stmt, null);
        }();
        enforce(code == SQLITE_OK);

        // And search..
        code = () @trusted {
            static immutable char[] zsql = import("findByName.sql");
            return sqlite3_prepare_v2(db, zsql.ptr, zsql.length, &searchStmt, null);
        }();
        enforce(code == SQLITE_OK);

        // and all
        code = () @trusted {
            static immutable char[] zsql = import("allPkgs.sql");
            return sqlite3_prepare_v2(db, zsql.ptr, zsql.length, &listStmt, null);
        }();
        enforce(code == SQLITE_OK);
    }

    /** 
     * Terminate underlying connections
     */
    void close() @trusted
    {
        if (db !is null)
        {
            sqlite3_finalize(stmt);
            sqlite3_finalize(searchStmt);
            sqlite3_finalize(listStmt);
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

        db.beginTransaction();
        scope (exit)
            db.endTransaction();

        foreach (pkg; eopkgEnumerator[])
        {
            int index;
            ++nPkgs;
            sqlite3_reset(stmt);
            stmt.bindText(++index, pkg.pkgID);
            stmt.bindText(++index, pkg.name);
            stmt.bindText(++index, pkg.version_);
            stmt.bindInt(++index, pkg.release);
            stmt.bindText(++index, pkg.homepage);
            stmt.bindText(++index, pkg.summary);
            stmt.bindText(++index, pkg.description);
            stmt.bindInt(++index, pkg.installed);
            const rc = sqlite3_step(stmt);
            enforce(rc == SQLITE_DONE);
        }
        stp.stop();
        writeln(stp.peek);
    }

    /** 
     * Yield a range of packages By Name.
     * Params:
     *   name = Name of the package
     */
    auto byName(scope ref const(char[]) name) @trusted
    {
        sqlite3_reset(searchStmt);
        // Bind the query
        searchStmt.bindText(1, name);
        return StatementEnumerator(searchStmt).prime;
    }

    auto list() @trusted
    {
        sqlite3_reset(listStmt);
        return StatementEnumerator(listStmt).prime;
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
    sqlite3_stmt* searchStmt;
    sqlite3_stmt* listStmt;
}

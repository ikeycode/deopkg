/*
 * SPDX-FileCopyrightText: Copyright © 2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * deopkg.context
 *
 * Encapsulates the eopkg internals and gives us a shared InterpContext
 * forPython
 *
 * Authors: Copyright © 2023 Serpent OS Developers
 * License: Zlib
 */

module deopkg.context;

@safe:

import pyd.pyd;
import pyd.embedded;
import std.experimental.logger;

/** 
 * Global context for eopkg
 * It wraps an InterpContext and initialises the right imports
 */
public final class EopkgContext
{

    /** 
     * Construct a new EopkgContext
     */
    this() @trusted
    {
        info("Initialising python");
        py_init();

        icontext = new InterpContext();
        icontext.pushDummyFrame();
        icontext.pisi = py_import("pisi");

        // Insert PackageDB + InstallDB
        icontext.pdb = icontext.py_eval("pisi.db.packagedb.PackageDB()");
        icontext.idb = icontext.py_eval("pisi.db.installdb.InstallDB()");
    }

    void close() @trusted
    {
        icontext.popDummyFrame();
        icontext = null;
        py_finish();
    }

private:

    InterpContext icontext;
}

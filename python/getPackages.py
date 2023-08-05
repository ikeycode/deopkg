#
# getPackages():
#
# A specialist generator function to emit a range of `EopkgPackage` back to
# deopkg for processing
#
def getPackages():
    import pisi.api
    import deopkg

    pdb = pisi.db.packagedb.PackageDB()
    avail = pdb.list_packages(None)

    for pkgID in avail:
        pkg, repo = pdb.get_package_repo(pkgID)
        d = deopkg.EopkgPackage()
        d = EopkgPackage()
        d.pkgID = "{0};{1}-{2};{3};{4}".format(
                pkg.name,
                pkg.version,
                pkg.release,
                pkg.architecture,
                repo)

        d.name = pkgID
        d.summary = pkg.summary["en"]
        d.version = pkg.version
        yield d
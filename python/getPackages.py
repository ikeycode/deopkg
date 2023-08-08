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
    idb = pisi.db.installdb.InstallDB()

    avail = pdb.list_packages(None)
    installed = idb.list_installed()

    all_names = list(set(avail + installed))

    # Convert pisi metadata to a deopkg
    def asDeopkg(input, data="installed"):
        d = deopkg.EopkgPackage()
        d.pkgID = "{};{}-{};{};{}".format(
            input.name,
            input.version,
            input.release,
            input.architecture,
            data
        )
        d.name = input.name
        d.version = input.version
        d.release = long(input.release)
        d.summary = input.summary["en"]
        d.description = input.description["en"]
        d.homepage = input.source.homepage
        return d

    for pkgID in all_names:
        installed = idb.get_package(pkgID) if idb.has_package(pkgID) else None
        available, repo = pdb.get_package_repo(pkgID) if pdb.has_package(pkgID) else (None, None)

        if installed is not None and repo is not None:
            data = "installed:{}".format(repo)
            d = asDeopkg(installed, data)
            d.installed = True
            yield d
        if installed is not None and repo is None:
            yield asDeopkg(installed)
        if available is not None:
            yield asDeopkg(available, repo)

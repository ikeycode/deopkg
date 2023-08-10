def getRepos():
    import pisi
    import deopkg

    rdb = pisi.db.repodb.RepoDB()
    for repo in rdb.list_repos(False):
        dr = deopkg.EopkgRepo()
        dr.uri = rdb.get_repo_url(repo)
        dr.name = repo
        dr.enabled = rdb.repo_active(repo)
        yield dr
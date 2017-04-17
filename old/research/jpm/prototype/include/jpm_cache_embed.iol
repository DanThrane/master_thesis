include "jpm_cache.iol"

outputPort JPMCache {
    Interfaces: JPMCacheIface
}

embedded {
    Jolie:
        "jpm_cache.ol" in JPMCache
}

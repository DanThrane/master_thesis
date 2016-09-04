include "jpm_module.iol"

type InstallationToCacheRequest: void {
    .source: JPMModuleDependency
}

type InstallationToPackageRequest: void {
    .packageLocation: string
    .packageRequest: InstallationToCacheRequest
}

interface JPMCacheIface {
    RequestResponse:
        setCacheHome(string)(void),
        /**
         * Installs a package into the cache. The supplied source must be a 
         * GitHub type.
         */
        installToCache(InstallationToCacheRequest)(void),
        /**
         * Installs a package from the cache into a package. The supplied 
         * source must be a GitHub type source.
         */
        installToPackage(InstallationToPackageRequest)(void)
}

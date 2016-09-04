include "jpm_cache.iol"

include "file.iol"
include "console.iol"
include "string_utils.iol"

include "git_embed.iol"
include "github_embed.iol"

execution { concurrent }

inputPort JPMCache {
    Location: "local"
    Interfaces: JPMCacheIface
}

init
{
    getFileSeparator@File()(global.fileSep)
}

/**
 * Locates where a package of a specific version should be stored in the cache.
 * 
 * This may be used both for installing into the cache, and retrieving a 
 * package.
 * 
 * Input parameters
 * ----------------
 * 
 *   - `packageRequest: InstllationToCacheRequest`: The package request
 * 
 * Output variables
 * ----------------
 * 
 *   - `cacheLocation: string`: The location the package request is to be 
 *     located at
 * 
 */
define locate_package
{
    if (!is_defined(global.cacheHome)) {
        throw(CacheNotInitialized)
    };
    cacheLocation = global.cacheHome + global.fileSep;

    if (packageRequest.source == MODULE_TYPE_GITHUB) {
        dep -> packageRequest.source;
        cacheLocation += "github" + global.fileSep + 
            dep.owner + global.fileSep + 
            dep.name + global.fileSep;
        
        if (is_defined(dep.version)) {
            cacheLocation += dep.version
        } else {
            cacheLocation += "latest"
        }
    } else {
        throw(InvalidRequest)
    }
}

main
{
    [setCacheHome(home)(resp) {
        global.cacheHome = home
    }]

    [installToCache(packageRequest)(resp) {
        locate_package;
        exists@File(cacheLocation)(cachedVersionExists);
        if (cachedVersionExists) {
            if (!is_defined(packageRequest.source.version)) {
                pull@Git({
                    .directory = cacheLocation,
                    .remote = "origin",
                    .branch = "master"
                })()
            }
        } else {
            getRepository@GitHub({ 
                .owner = packageRequest.source.owner,
                .repository = packageRequest.source.name
            })(repository);

            if (is_defined(repository.message)) {
                throw(GitRepositoryNotFound)
            } else {
                cloneRepo@Git({
                    .uri = repository.git_url,
                    .directory = cacheLocation
                })();
                
                if (is_defined(packageRequest.source.version)) {
                    checkout@Git({
                        .directory = cacheLocation,
                        .startPoint = packageRequest.source.version
                    })()
                }
            }
        }
    }]

    [installToPackage(request)(resp) {
        packageRequest -> request.packageRequest;
        locate_package;

        exists@File(cacheLocation)(cachedExists);
        if (cachedExists) {
            installedLibs = request.packageLocation + global.fileSep + 
                "installed_lib";
            installedInclude = request.packageLocation + global.fileSep + 
                "installed_include";
            installedSources = request.packageLocation + global.fileSep + 
                "installed_sources" + global.fileSep;

            sourceLib = cacheLocation + global.fileSep + "lib";
            sourceInclude = cacheLocation + global.fileSep + "include";
            sourceSources = cacheLocation + global.fileSep;

            exists@File(sourceLib)(sourceLibExists);
            exists@File(sourceInclude)(sourceIncludeExists);


            if (sourceLibExists) {
                copyDir@File({ .from = sourceLib, .to = installedLibs })()
            };

            if (sourceIncludeExists) {
                copyDir@File({
                    .from = sourceInclude,
                    .to = installedInclude
                })()
            };

            exists@File(installedSources)(hasInstalledSources);
            if (!hasInstalledSources) {
                mkdir@File(installedSources)()
            };

            list@File({ .directory = sourceSources })(sources);
            for (i = 0, i < #sources.result, i++) {
                current -> sources.result[i];
                if (current != "lib" && current != "include" && 
                        current != ".git" && current != "module.json") {
                    replaceAll@StringUtils(current { 
                        .regex = cacheLocation, 
                        .replacement = installedSources 
                    })(destination);

                    with (copyRequest) {
                        .from = cacheLocation + global.fileSep + current;
                        .to = installedSources + global.fileSep + current
                    };
                    copyDir@File(copyRequest)()
                }
            }
        } else {
            throw(PackageNotFoundInCache)
        }
    }]
}

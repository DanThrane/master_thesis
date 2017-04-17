include "jpm.iol"

include "console.iol"
include "file.iol"
include "string_utils.iol"
include "time.iol"

include "environment.iol"
include "advanced_http.iol"

include "github_embed.iol"
include "git_embed.iol"

include "jpm_database.iol"
include "jpm_cache_embed.iol"

execution { concurrent }

inputPort JPM {
    Location: "local"
    Interfaces: JPMIFace
}

outputPort Self {
    Interfaces: JPMIFace
}

outputPort JPMDatabase {
    Interfaces: JPMDatabaseIface
}

outputPort JPMModule {
    Interfaces: JPMModuleIface
}

embedded {
    Jolie:
        "jpm_database.ol" in JPMDatabase,
        "jpm_module.ol" in JPMModule,
        "jpm.ol" in Self
}

init
{
    getProperty@Environment("user.home")(home);
    getFileSeparator@File()(sep);
    global.fileSep = sep;
    global.DATA_HOME = home + sep + ".jpm" + sep;
    exists@File(global.DATA_HOME)(homeExists);
    if (!homeExists) {
        mkdir@File(global.DATA_HOME)()
    };
    
    global.CACHE_HOME = global.DATA_HOME + sep + "cache";
    exists@File(global.CACHE_HOME)(cacheExists);
    if (!cacheExists) {
        mkdir@File(global.CACHE_HOME)()
    };
    setCacheHome@JPMCache(global.CACHE_HOME)()
}

constants {
    CENTRAL_OWNER = "DanThrane",
    CENTRAL_REPOSITORY = "jpm-specs",
    CENTRAL_REPOSITORY_URL = "https://github.com/DanThrane/jpm-specs.git",
    SEMVER_REGEX = "(\\d+)\\.(\\d+)\\.(\\d+)",
}

/**
 * Installs a module from the central repository.
 * 
 * Input parameters
 * ----------------
 * 
 *   - `locator: JPMLocator`: The locator which specifies which package to 
 *      install
 *   - `repositoryHome: string`
 * 
 *
 * Throws
 * ------
 * 
 *   - `MalformedSource`: If the source found at the locator is malformed
 *   - `MalformedVersion`: If the version given is malformed
 */
define install_central_module
{
    connect@JPMDatabase(global.DATA_HOME)();
 
    // TODO Move to SemVer
    match@StringUtils(locator.version { .regex = SEMVER_REGEX })(matches);
 
    if (matches == 1) {
        findRequest.name = locator.module;
        findRequest.version_major = matches.group[1];
        findRequest.version_minor = matches.group[2];
        findRequest.version_patch = matches.group[3];
        find@JPMDatabase(findRequest)(findResponse);
        if (!findResponse.found) {
            println@Console(locator.module)();
            throw(CentralModuleNotFound, locator.module)
        };
        response -> findResponse.result;

        parseDependencyModule@JPMModule(response.source)(parsedSource);

        if (parsedSource == MODULE_TYPE_GITHUB) {
            cacheRequest.source << parsedSource;
            installToCache@JPMCache(cacheRequest)();

            undef(cacheRequest);
            cacheRequest.packageRequest.source << parsedSource;
            cacheRequest.packageLocation = repositoryHome;
            installToPackage@JPMCache(cacheRequest)();

            for (i = 0, i < #response.dependencies, i++) {
                installRequest = repositoryHome;
                installRequest.locator << response.dependencies[i];

                installModule@Self(installRequest)()
            }
        } else {
            throw(MalformedSource)
        }
    } else {
        throw(MalformedVersion)
    }
}


/**
 * Updates the local specs repository.
 *
 * If the repository does not exist it will be cloned, otherwise that same 
 * repository will be pulled to retrieve any changes. Following this the 
 * entries from the specs repository will be inserted into the local database. 
 * All duplicates entries should be updated, as guaranteed by the JPMDatabase 
 * service.
 * 
 * Input parameters
 * ----------------
 * 
 * None
 * 
 * Output parameters
 * -----------------
 * 
 * None
 * 
 */
define update_specs
{
    connect@JPMDatabase(global.DATA_HOME)();

    repoLocation = global.DATA_HOME + "specs";
    exists@File(repoLocation)(repoExists);

    if (repoExists) {
        pull@Git({
            .directory = repoLocation,
            .remote = "origin",
            .branch = "master"
        })()
    } else {
        cloneRepo@Git({
            .uri = CENTRAL_REPOSITORY_URL,
            .directory = repoLocation
        })()
    };

    // The following code gets a bit ugly, but essentially traverses all 
    // the directories, until we finally reach the directories which 
    // contains the specifications.
    getFileSeparator@File()(sep);
        
    repoLocation = repoLocation + sep + "specs";
    list@File({  .directory = repoLocation, .regex = "[^\\.]+" })(l1Dirs);
    for (x = 0, x < #l1Dirs.result, x++) {
        l1Dir = repoLocation + sep + l1Dirs.result[x];
        list@File({ .directory = l1Dir, .regex = "[^\\.]+" })(l2Dirs);

        for (y = 0, y < #l2Dirs.result, y++) {
            l2Dir = l1Dir + sep + l2Dirs.result[y];
            list@File({ .directory = l2Dir, .regex = "[^\\.]+" })(l3Dirs);

            for (z = 0, z < #l3Dirs.result, z++) {
                l3Dir = l2Dir + sep + l3Dirs.result[z];
                list@File({ .directory = l3Dir, .regex = ".+\\.json" })(l4Dirs);

                for (i = 0, i < #l4Dirs.result, i++) {
                    file = l3Dir + sep + l4Dirs.result[i];

                    parseModule@JPMModule(file)(module);
                    insertModule@JPMDatabase(module)()
                }
            }   
        }
    }
}

/**
 * Generates a 'specs change' file, for a given version of a package.
 * 
 * Input parameters
 * ----------------
 * 
 *  - `directory: string`: The path to the directory of the package being 
 *                         published
 *  - `gitBranch: string`: The branch to add the change file to
 *  - `lowercase: string`: The lowercase name of the package
 *  - `module: JPMModule`: The module to write the change file for
 * 
 */
define generate_specs_change
{
    substring@StringUtils(lowercase { .begin = 0, .end = 1 })(l1);
    substring@StringUtils(lowercase { .begin = 1, .end = 2 })(l2);

    getFileSeparator@File()(sep);
    baseFolder = global.DATA_HOME + "specs" + sep + "specs" + sep + l1 + sep + 
        l2 + sep + lowercase;

    exists@File(baseFolder)(baseExists);
    if (!baseExists) {
        mkdir@File(baseFolder)()
    };

    fileName = baseFolder + sep + module.version.major + "." + 
        module.version.minor + "." + module.version.patch + ".json";

    exists@File(fileName)(versionExists);

    if (versionExists) {
        throw(VersionAlreadyExists)
    };

    getCommitHash@Git({
        .branch = "origin/master",
        .directory = directory
    })(module.source.version);

    if (module.source.version == null) {
        throw(PackageNotCommitted)
    };

    with (writeRequest) {
        .content << module;
        .filename = fileName;
        .format = "json";
        .format.indent = true
    };
    writeFile@File(writeRequest)()
}

/**
 * Generates a specs change commit and pushes it to the relevant remote.
 * 
 * Input parameters
 * ----------------
 * 
 *   - `gitBranch: string`: The branch to push the change to
 *   - `gitDirectory: string`: The path to the specs repository
 *   - `auth: GitHubAuth`: The Github authentication to use
 * 
 */
define generate_specs_commit
{
    addAndCommit@Git({ 
        .directory = gitDirectory, 
        .message = commitMessage
    })(status);

    addRemote@Git({
        .directory = gitDirectory,
        .name = "origin-fork",
        .url = "https://" + auth.username + ":" + auth.password + 
            "@github.com/" + auth.username + "/jpm-specs.git"
    })(status);

    push@Git({
        .directory = gitDirectory,
        .remote = "origin-fork",
        .branch = gitBranch
    })(status);

    removeRemote@Git({
        .directory = gitDirectory,
        .name = "origin-fork"
    })(status);

    checkout@Git({
        .directory = gitDirectory,
        .startPoint = "master"
    })(status)
}

main
{
    [initModule(request)(response) {
        with (writeRequest) {
            .content << request.module;
            .filename = request + global.fileSep + "module.json";
            .format = "json";
            .format.indent = true
        };
        writeFile@File(writeRequest)();
        response = undefined
    }]

    [hasFork(auth)(response) {
        getRepository@GitHub({
            .owner = auth.username, 
            .repository = CENTRAL_REPOSITORY 
        })(repo);

        response = is_defined(repo)
    }]

    [createSpecsFork(auth)(response) {
        with (forkRequest) {
            .owner = CENTRAL_OWNER;
            .repository = CENTRAL_REPOSITORY;
            .auth << auth
        };
        forkRepository@GitHub(forkRequest)(response);
        
        while(!is_defined(repo)) {
            sleep@Time(5000)();
            getRepository@GitHub({
                .owner = auth.username, 
                .repository = CENTRAL_REPOSITORY 
            })(repo)
        }
    }]

    [publishModule(request)(response) {
        locateModule@JPMModule(request.location)(module); 
        auth -> request.auth;

        directory = request.location;

        toLowerCase@StringUtils(module.name)(lowercase);

        replaceAll@StringUtils(lowercase {
            .regex = " ",
            .replacement = "_"
        })(lowercase);

        gitDirectory = global.DATA_HOME + "specs";
        
        gitBranch = branch = "p-" + lowercase + "-" + 
            module.version.major +  "-" + module.version.minor + "-" + 
            module.version.patch;

        commitMessage = "Adds " + lowercase + "@" + 
            module.version.major + "." + module.version.minor + 
            "." + module.version.patch;        

        // Checkout the appropiate branch before generating the specs change 
        // file
        checkoutBranch@Git({
            .directory = gitDirectory,
            .branch = gitBranch
        })(status);

        // Generates the new JSON file which goes into the specs repository
        generate_specs_change;

        // Commits and pushes to local fork
        generate_specs_commit;
        
        // Creates a pull request from the local fork
        with (prRequest) {
            .title = commitMessage;
            .username = auth.username;
            .branch = gitBranch;
            .base = "master";
            .body = "Generated by JPM";
            .owner = CENTRAL_OWNER;
            .repository = CENTRAL_REPOSITORY;
            .auth << auth
        };

        createPullRequest@GitHub(prRequest)(result)
    }]

    [installModule(request)(response) {
        repositoryHome = request;

        parseDependencyModule@JPMModule(request.locator)(parsed);
        if (parsed == MODULE_TYPE_GITHUB) {
            cacheRequest.source << parsed;
            installToCache@JPMCache(cacheRequest)();
            undef(cacheRequest);
            cacheRequest.packageRequest.source << parsed;
            cacheRequest.packageLocation = repositoryHome;
            installToPackage@JPMCache(cacheRequest)()
        } else if (parsed == MODULE_TYPE_CENTRAL) {
            locator << request.locator;
            install_central_module
        } else {
            nullProcess
        };
        response = undefined
    }]

    [searchModules(request)(response) {
        connect@JPMDatabase(global.DATA_HOME)();
        search@JPMDatabase(request)(response)
    }]

    [updateIndicies(request)(response) {
        update_specs
    }]
}

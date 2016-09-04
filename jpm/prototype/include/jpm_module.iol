include "semver.iol"

/**
 * Represents a single JPM Module. The module for a package is stored in 
 * `module.json` in the root directory of the package. 
 * 
 * Attributes
 * ----------
 *   
 *   - name:         The name of the module, can only contain a-z and 0-9.
 *   - description:  Free text description of the module.
 *   - version:      The current version of the module. It is expected that the 
 *                   Git repository found at the `source` should contain a tag 
 *                   matching the SemVer. Labels are ignored for the tags.
 *   - dependencies: The dependencies of the project stored as locators. 
 *   - source:       Where to find the Git repository for this package.
 *   - private:      `true` if this package is private, otherwise `false`. If a 
 *                   package is marked as private, it cannot be published to the
 *                   central repository.
 */
type JPMModule: void {
    .name: string
    .description: string
    .version: SemVer
    .dependencies[0,*]: JPMLocator
    .source: JPMLocator
    .private: bool
}

/**
 * Represents a repository stored locally. The location specifies where the 
 * module is stored (uri) and the module specifies the in-memory view of the 
 * module.
 */
type LocalJPMModule: void {
    .location: string
    .module: JPMModule
}

/**
 * Represents a JPM dependency as it can be specified in the module file. The
 * parsed version of this type is JPMModuleDependency.
 */
type JPMLocator: void {
    .module: string
    .version?: string
}

/**
 * Represents a parsed version of the JPMLocator. The root value represents
 * the type of dependency (e.g. GitHub, Git or central). The fields then specify
 * how the dependency should be retrieved.
 *
 * Attributes
 * ----------
 *
 *  - owner:     The owner of the repository. Applies only to 
 *               `MODULE_TYPE_GITHUB`
 *  - name:      The name of the repository. Applies to `MODULE_TYPE_GITHUB` 
 *               and `MODULE_TYPE_CENTRAL`
 *  - version:   The commit-ish to use for retrieving the correct version of 
 *               the package. If undefined, the newest will be used. Applies to
 *               all valid module types.
 */
type JPMModuleDependency: int {
    .owner?: string
    .name?: string
    .version?: string
}

constants {
    MODULE_TYPE_GITHUB = 0,
    MODULE_TYPE_CENTRAL = 2,
    MODULE_TYPE_UNKNOWN = -1
}

interface JPMModuleIface {
    OneWay:
    RequestResponse:
        parseModule(string)(JPMModule),
        locateModule(string)(JPMModule) throws RepositoryNotFound,
        writeModule(LocalJPMModule)(void),
        parseDependencyModule(JPMLocator)(JPMModuleDependency),
        validate(JPMModule)(void) throws InvalidRepository
}

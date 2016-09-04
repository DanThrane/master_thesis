include "jpm_module.iol"
include "github.iol"

type ModuleLocation: string {
    .module: JPMModule
}

type GitHubInstallationRequest: string {
    .owner: string
    .repository: string
}

type ModuleInstallationRequest: string {
    .locator: JPMLocator
}

type SearchResponse: void {
    .results[0,*]: JPMModule
}

type PublishRequest: void {
    .auth: GitHubAuth
    .location: string
}

interface JPMIFace {
    RequestResponse:
        initModule(ModuleLocation)(void),
        publishModule(PublishRequest)(undefined),
        installModule(ModuleInstallationRequest)(undefined),
        searchModules(string)(SearchResponse),
        updateIndicies(void)(void),
        hasFork(GitHubAuth)(bool),
        createSpecsFork(GitHubAuth)(void)
}

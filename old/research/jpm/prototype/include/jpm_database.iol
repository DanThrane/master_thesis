include "jpm_module.iol"

type DBSearchResponse: void {
    .results[0, *]: JPMModule
}

type FindRequest: void {
    .name: string
    .version_major: string
    .version_minor: string
    .version_patch: string
}

type FindResponse: void {
    .result?: JPMModule
    .found: bool
}

interface JPMDatabaseIface {
    RequestResponse:
        connect(string)(void),
        insertModule(JPMModule)(void),
        search(string)(DBSearchResponse),
        find(FindRequest)(FindResponse)
}

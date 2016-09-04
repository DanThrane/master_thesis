include "jpm_module.iol"
include "console.iol"
include "file.iol"
include "string_utils.iol"
include "runtime.iol"

execution { concurrent }

inputPort JPMModule {
    Location: "local"
    Interfaces: JPMModuleIface
}

constants {
  GITHUB_INSTALL_REGEX = "(.+)\\/(.+)"
}

main
{
    [writeModule(request)(resp) {
        getFileSeparator@File()(sep);
        with (writeRequest) {
            .content << request.module;
            .filename = request.location + sep + "module.json";
            .format = "json";
            .format.indent = true
        };

        writeFile@File(writeRequest)()
    }]

    [locateModule(location)(module) {
        scope(module_reading)
        {
            getFileSeparator@File()(sep);
            install(FileNotFound => throw(RepositoryNotFound));
        
            file = location + sep + "module.json";
            readFile@File({ .filename = file, .format = "json" })(module)
        }
    }]

    [parseModule(location)(module) {
        readFile@File({ .filename = location, .format = "json" })(module)
    }]

    [validate(module)(void) {
        // TODO Validate that we're the owner and that the specified source is 
        // valid
        nullProcess
    }]

    [parseDependencyModule(locator)(response) {
        input -> locator.module;
        if (is_defined(locator.version)) {
            response.version = locator.version
        };
        match@StringUtils(input { .regex = GITHUB_INSTALL_REGEX })(matches);
        if (matches == 1) {
            response << MODULE_TYPE_GITHUB {
                .owner = matches.group[1],
                .name = matches.group[2]
            }
        } else {
            response << MODULE_TYPE_CENTRAL {
                .name = input
            }
        }
    }]
}

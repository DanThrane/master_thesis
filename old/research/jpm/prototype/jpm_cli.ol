include "console.iol"
include "file.iol"
include "string_utils.iol"
include "runtime.iol"

include "jpm.iol"
include "jpm_module.iol"
include "git.iol"
include "github_embed.iol"
include "advanced_http.iol"
include "console_ui.iol"

outputPort JPM {
    Interfaces: JPMIFace
}

outputPort JPMModule {
    Interfaces: JPMModuleIface
}

// Just embed JPM for now, although we might want some system daemon which runs 
// in the background. But that would probably only be needded if we can gain 
// any performance benefits.
embedded {
    Jolie:
        "jpm.ol" in JPM,
        "jpm_module.ol" in JPMModule
}

define cmd_init
{
    println@Console("Initializing module...")();
    displayPrompt@ConsoleUI("Package name")(locator.name);
    displayPrompt@ConsoleUI("Description")(locator.description);
    displayPrompt@ConsoleUI("GitHub User")(ghUser);
    displayPrompt@ConsoleUI("Repository")(ghRepo);
    locator.version << {
        .major = 0,
        .minor = 1,
        .patch = 0
    };
    locator.source.module = ghUser + "/" + ghRepo;
    displayYesNoPrompt@ConsoleUI("Mark the package as private?")
        (locator.private);

    println@Console()();
    println@Console("This is what I got:")();
    valueToPrettyString@StringUtils(locator)(prettyLocator);
    println@Console(prettyLocator)();
    displayYesNoPrompt@ConsoleUI("Does this look right?")(confirm);

    if (confirm) {
        initRequest = args[0];
        initRequest.module << locator;
        initModule@JPM(initRequest)();
        println@Console("Module successfully initialized in " + args[0])()
    }
}

define cmd_search
{
    if (#args == 3) {
        searchModules@JPM(args[2])(results);
        for (i = 0, i < #results.results, i++) {
            current -> results.results[i];
            version -> current.version;
            println@Console(current.name + "@" + version.major + 
                "." +  version.minor + "." + version.patch +
                 ": " + current.description)()
        }
    } else {
        println@Console("Unknown search format")()
    }
}

define cmd_install
{
    locateModule@JPMModule(args[0])(module);
    if (#args == 2) {
        println@Console("Installing dependencies")();
        displaySpinner@ConsoleUI()();
        // Install all dependencies missing from the module
        for (i = 0, i < #module.dependencies, i++) {
            undef(request);
            request = args[0];
            request.locator <<  module.dependencies[i];
            installModule@JPM(request)()
        };
        stopSpinner@ConsoleUI()()
    } else {
        println@Console("Unknown arguments!")()
    }
}

define authenticate_github
{
    success = false;

    while (!success) {
        displayPrompt@ConsoleUI("GitHub username")(auth.username);
        displayPasswordPrompt@ConsoleUI("GitHub password")(auth.password);

        authenticate@GitHub(auth)(success);
        if (!success) {
            println@Console()();
            println@Console("Invalid username/password. Try again!")();
            undef(auth)
        }
    }
}

define cmd_publish
{
    println@Console("This requies a forked copy of jpm-specs. Please " + 
        "authenticate via GitHub")();

    authenticate_github;

    hasFork@JPM(auth)(hasFork);
    if (!hasFork) {
        println@Console("Couldn't find an existing fork of jpm-specs")();
        displayYesNoPrompt@ConsoleUI("Create one?")(createFork);
        if (createFork) {
            displaySpinner@ConsoleUI()();
            createSpecsFork@JPM(auth)();
            stopSpinner@ConsoleUI()()
        }
    };

    println@Console("Updating local indicies")();
    updateIndicies@JPM()();
    
    println@Console("Publishing changes")();
    displaySpinner@ConsoleUI()();
    with (publishRequest) {
        .location = args[0];
        .auth << auth
    };
    publishModule@JPM(publishRequest)();
    stopSpinner@ConsoleUI()();
    
    println@Console("Changes successfully published!")()
}

define cmd_help
{
    println@Console("JPM - The Jolie Package Manager
Version 0.1.0

Usage: jpm <command> <arguments>

Available commands:
-------------------

  - init        Initializes a package in the current directory
  - install     Installs the dependencies, which are located in module.json
  - update      Updates the local database from the central repository
  - status      Prints out JPM's knowledge of the package placed in the 
                current directory
  - publish     Publishes the package in the current directory to the 
                central repository.
  - search <q>  Searches the local database for a given package
  - help        This command
")()
}

define cmd_update
{
    println@Console("Called update")();
    updateIndicies@JPM()()
}

define cmd_status
{
    locateModule@JPMModule(args[0])(module);
    valueToPrettyString@StringUtils(module)(prettyModule);
    println@Console(prettyModule)()
}

main
{
    if (#args < 2) {
        println@Console("Usage: jpm <command> [options]")();
        println@Console("See 'jpm help' for more information")()
    } else {
        if (args[1] == "init") {
            cmd_init
        } else if (args[1] == "install") {
            cmd_install
        } else if (args[1] == "search") {
            cmd_search
        } else if (args[1] == "publish") {
            cmd_publish
        } else if (args[1] == "help") {
            cmd_help
        } else if (args[1] == "update") {
            cmd_update
        } else if (args[1] == "status") {
            cmd_status
        } else {
            println@Console("Unknown command jpm " + args[1])()
        }
    }
}

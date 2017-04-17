interface EnvironmentIface {
    RequestResponse:
        getEnvironmentVariable(string)(string),
        getProperty(string)(string)
}


outputPort Environment {
    Interfaces: EnvironmentIface
}

embedded {
    Java:
        "dk.thrane.jolie.environment.EnvironmentService" in Environment
}

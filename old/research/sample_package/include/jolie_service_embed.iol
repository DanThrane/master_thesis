include "jolie_service.iol"

outputPort JolieService {
    Interfaces: EmbeddedJolieInterface
}

embedded {
    Jolie:
        "jolie_service.ol" in JolieService
}

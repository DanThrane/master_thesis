include "jolie_service.iol"

execution { concurrent }

inputPort JolieService {
    Location: "local"
    Interfaces: EmbeddedJolieInterface
}

main
{
    [incrementer(req)(res) {
        res = req + 1
    }]
}

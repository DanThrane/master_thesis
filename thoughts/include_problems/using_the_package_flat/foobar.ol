include "foobar.iol" // Include is wrong now

execution { concurrent }

inputPort FoobarPort {
    Location: "local"
    Interfaces: A
}

main
{
    [sampleOperation(req)(res) {
        res = req + 10
    }]
}
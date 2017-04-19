include "file.iol"
include "console.iol"

main
{
    readFile@File({ .filename = "resource.txt" })(result);
    println@Console(result)()
}

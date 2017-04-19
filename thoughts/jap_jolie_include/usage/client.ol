include "jar:file:./foobar.jap!/foobar.iol"
include "console.iol"

outputPort FoobarPort {
    Interfaces: A
}

embedded {
  Jolie: "jar:file:./foobar.jap!/foobar.ol" in FoobarPort
}

main
{
  sampleOperation@FoobarPort(10)(result);
  println@Console(result)()
}

include "foobar.iol"

outputPort FoobarPort {
    Interfaces: A
}

embedded {
  Jolie: "foobar.ol" in FoobarPort
}

interface A {
  RequestResponse: 
    sampleOperation(int)(int)
}

outputPort FoobarPort {
    Interfaces: A
}

embedded {
  Jolie: "foobar.ol" in FoobarPort
}

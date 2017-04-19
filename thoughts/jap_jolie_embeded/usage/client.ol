include "jar:file:./foobar.jap!/foobar.iol"
include "console.iol"

main
{
  sampleOperation@FoobarPort(10)(result);
  println@Console(result)()
}

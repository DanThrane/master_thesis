/*
This gives us some issues with the include statement however:

  - It is rather verbose
  - The existing conventions for what is automatically added to the include 
    paths are broken (we have to add the include part)
*/
include "jar:file:./foobar.jap!include/embed.iol"
include "console.iol"

main
{
  sampleOperation@FoobarPort(10)(result);
  println@Console(result)()
}

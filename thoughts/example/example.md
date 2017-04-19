This is how I currently imagine a package manager for Jolie would
work.  I have also attached the relevant code. I have purposely stayed
away from any technical details. The executable for the package
manager will be called `jpm` in this example.

In this first example we'll start with a simple client which will
require a small library. The library will be a simple calculator
library, which just sums some numbers together. The code for this
library can be seen in the calculator folder. The library exposes a
service with the following interface:

```
type SumRequest: void {
    .numbers[2,*]: int
}

interface CalculatorIface {
    RequestResponse:
        sum(SumRequest)(int)
}
```

With our small calculator library done, we would like to release it to
some package registry. Associated with every package should be some
metadata. Every Jolie package would be defined by a file which
contains this metadata. For the sake of discussion let's say that this
is a JSON, which contains a few properties:

```
{
    "name": "Calculator",
    "version": "1.0.0",
    "dependencies": [],
    "license": "MIT",
    "authors": ["Dan Sebastian Thrane <dathr12@student.sdu.dk>"]
}
```

The exact contents and format of the file is entirely up for
discussion. With this metadata, we should be able publish our package
to the public Jolie package registry.

```
$ cd $CALCULATOR_HOME
$ jpm publish
Are you sure you wish to release Calculator at version 1.0.0 to 
<registry>? [y/N]
> y
Uploading Calculator@1.0.0 to <registry>
... Done
```

This would make the package available on the registry. Using a tool,
such as a web UI or CLI, we should be able to view the different
packages available in the registry.

Creating a client, which uses this library then shouldn't be much
harder than creating a new `package.json` and listing it as a
dependency. We could do this manually or have the tool do it:

```
$ mkdir client
$ cd client
$ jpm init
Name [client]:
>
License [MIT]:
>
Authors:
> Author 1, Author 2

Generated 'package.json'
$ cat package.json
{
    "name": "client",
    "version": "1.0.0",
    "dependencies": [],
    "license": "MIT",
    "authors": ["Author 1", "Author 2"]
}
```

Adding the dependency could be done using either the tool or manually
editing the file:

```
$ jpm add-dependency Calculator
Found package 'Calculator' latest version is 1.0.0

Version [1.0.0]:
>

Added dependency to package.json

$ cat package.json
{
    "name": "client",
    "version": "1.0.0",
    "dependencies": [
        {
            "name": "Calculator",
            "version": "1.0.0"
        }
    ],
    "license": "MIT",
    "authors": ["Author 1", "Author 2"]
}
```

With our dependencies correctly listed, we should be able to instruct
the package manager to install them:

```
$ jpm install
Installing dependencies... Done
```

Now that the dependency is installed in our client package, we should
be able to use it just like we use the standard library. An example
client could look like this:

```
include "calculator/calculator_embed.iol"
include "console.iol"

main
{
    calcReq.numbers[0] = 1;
    calcReq.numbers[1] = 2;
    calcReq.numbers[2] = 3;
    calcReq.numbers[3] = 4;

    sum@Calculator(calcReq)(result);
    println@Console(result)()
}
```

Making the include statement work like that, will most likely require
some work, and will heavily depend on how we choose to install the
dependencies. This could for example be done with either JAP files or
simply deliver the files. Both of these appear to have issues, that
would need to be resolved. Although that discussion is probably better
kept for another time.

In the simplest case external services to be as easy to use. Similarly
I feel that it should be easy to switch between embedding a service
and having it be external. How exactly this should be done remains to
be seen. But I don't see any reason why it shouldn't work under the
system I propose.

Regards,
Dan
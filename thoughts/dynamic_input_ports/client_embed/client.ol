<include "calculator/calculator_embed.iol"
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

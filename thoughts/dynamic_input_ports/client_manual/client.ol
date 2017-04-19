include "calculator/calculator.iol"
include "console.iol"

outputPort Calculator {
    Location: "socket://localhost:8000"
    Protocol: sodep
    Interfaces: CalculatorIface
}

main
{
    calcReq.numbers[0] = 1;
    calcReq.numbers[1] = 2;
    calcReq.numbers[2] = 3;
    calcReq.numbers[3] = 4;

    sum@Calculator(calcReq)(result);
    println@Console(result)()
}

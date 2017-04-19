include "calculator.iol"

execution { concurrent }

constants {
    CALCULATOR_LOCATION = "socket://localhost:8000",
    CALCULATOR_PROTOCOL = sodep
}

inputPort Calculator {
    Interfaces: CalculatorIface
    Location: CALCULATOR_LOCATION
    Protocol: CALCULATOR_PROTOCOL
}

main
{
    [sum(request)(sum) {
        sum = 0;
        for (i = 0, i < #request.numbers, i++) {
            sum += request.numbers[i]
        }
    }]
}

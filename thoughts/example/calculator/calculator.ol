include "calculator.iol"

execution { concurrent }

inputPort Calculator {
    Interfaces: CalculatorIface
    Location: "local"
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

include "calculator.iol"

outputPort Calculator {
    Interfaces: CalculatorIface
}

embedded {
    Jolie:
        "calculator.ol" in Calculator
}

type SumRequest: void {
    .numbers[2,*]: int
}

interface CalculatorIface {
    RequestResponse:
        sum(SumRequest)(int)
}

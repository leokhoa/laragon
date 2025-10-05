# intdiv0 --- do integer division

#
# Arnold Robbins, arnold@skeeve.com, Public Domain
# July, 2014
#
# Name changed from div() to intdiv()
# April, 2015
#
# Changed to intdiv0()
# April, 2016

function intdiv0(numerator, denominator, result)
{
    split("", result)

    numerator = int(numerator)
    denominator = int(denominator)
    result["quotient"] = int(numerator / denominator)
    result["remainder"] = int(numerator % denominator)

    return 0.0
}

# adequate_math_precision --- return true if we have enough bits
#
# Andrew Schorr, aschorr@telemetry-investments.com, Public Domain
# May 2017

function adequate_math_precision(n)
{
    return (1 != (1+(1/(2^(n-1)))))
}

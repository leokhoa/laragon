# tocsv.awk --- convert data to CSV format
#
# Arnold Robbins, arnold@skeeve.com, Public Domain
# April 2023

function tocsv(fields, sep,     i, j, nfields, result)
{
    if (length(fields) == 0)
        return ""

    if (sep == "")
        sep = ","
    delete nfields
    for (i = 1; i in fields; i++) {
        nfields[i] = fields[i]
        if (nfields[i] ~ /["\n]/ || index(nfields[i], sep) != 0) {
            gsub(/"/, "\"\"", nfields[i])       # double up the double quotes
            nfields[i] = "\"" nfields[i] "\""   # wrap in double quotes
        }
    }

    result = nfields[1]
    j = length(nfields)
    for (i = 2; i <= j; i++)
        result = result sep nfields[i]

    return result
}
function tocsv_rec(sep,     i, fields)
{
    delete fields
    for (i = 1; i <= NF; i++)
        fields[i] = $i

    return tocsv(fields, sep)
}

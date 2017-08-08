# Globals to make R CMD check not spit out "no visible binding for global 
#   variable" notes.
# Basically, R CMD check doesn't like it when you don't quote the "V1" in
#   a call like DT[, V1].
# See: http://stackoverflow.com/a/12429344
# Also: see hadley's comments on his own post there. They're great.

utils::globalVariables(c('.'
                         , '.I'
                         , '.id'
                         , 'field'
                         , 'index'
                         , 'V1'
                         , 'V2'
                       ))
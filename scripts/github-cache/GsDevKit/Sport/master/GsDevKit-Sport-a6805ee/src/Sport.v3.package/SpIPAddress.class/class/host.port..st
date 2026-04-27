instanceCreation
host: aHostAddress port: aPortNumber 
    "^an SpSocketAddress
    I create a new instance of myself which represents an IP address/port combination
    (a TCP/IP address, really).  Note that aHostAddress must be a 
    four element byte array (e.g. #[ 127 0 0 1 ]) ."

    ^self new host: aHostAddress port: aPortNumber

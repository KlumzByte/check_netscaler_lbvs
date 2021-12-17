**Netscaler LBVS check**

Copyright (C) 2016 KlumzByte. All rights reserved  
This program is free software; you can redistribute it or modify  
it under the terms of the GNU General Public License  

Tested on the following device:

Netscaler MPX 8200

Usage: 
<pre>
./check_netscaler_lbvs.pl

 -h, --help
    Print help screen
 -H, --hostname HOSTNAME
   Host to check HOSTNAME
 -C, --community NAME
   Community string. SNMP version 2c only. (default: public)
 -p, --port INT
   SNMP agent port. (default: 161)
 -t, --timeout=INTEGER
   Seconds before plugin times out (default: 10)
 -L, --lbvs=STRING
   Load Balancing Virtual Server OID
 -G, --gateway
   NetScaler Gateway (default: off)
</pre>

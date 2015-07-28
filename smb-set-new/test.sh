#!/bin/bash
for((i=3;i<=$#;i++)) 
do  
    eval testuser=\$$i 
	sed  "s/@${testuser}//g" aa.conf
done

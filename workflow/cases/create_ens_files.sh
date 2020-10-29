#!/bin/ksh 

nanals=10
memct=1
while [ $memct -le $nanals ];do
   MEM=`printf %3.3i $memct`
   cat  cntl.template | sed -e "s/XXX/${memct}/g" > cntl_mem${MEM}.yaml
   cat  cntl_ocn_ens.template | sed -e "s/XXX/${memct}/g" > cntl_ocn_ens_mem${MEM}.yaml
   memct=`expr $memct + 1`
done

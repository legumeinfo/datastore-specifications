#/bin/sh

for file in *.yml; do 
  echo
  echo "===== WORKING ON $file ====="
  ds_souschef.pl -conf $file; 
  echo
done

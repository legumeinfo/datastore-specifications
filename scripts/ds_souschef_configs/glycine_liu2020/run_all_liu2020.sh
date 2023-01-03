#/bin/sh

for file in conf*; do 
  echo
  echo "===== WORKING ON $file ====="
  ds_souschef.pl -conf $file; 
  echo
done

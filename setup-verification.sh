#!/bin/bash

chmod +x script1.sh script2.sh
echo "Ejecutando script1.sh: Errores se guardarán en script1_error"
./script1.sh 2>/dev/script1_error
echo "Ejecutando script2.sh: Errores se guardarán en script2_error"
./script2.sh 2>/dev/script2_error
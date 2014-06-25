#!/bin/bash

echo "Iniciando todas las máquinas virtuales"
for i in `nova list | awk -F \| ' { print $2}' | grep -v ID ` ; do nova start $i; done

#!/bin/bash

/usr/srb/MCAT/bin/ingestUsergroup $1 '' staff '' '' ''
/usr/srb/MCAT/bin/modifyShibMapping addToMapping $1 $1


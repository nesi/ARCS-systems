Bulk Data Transfer Scripts
~~~~~~~~~~~~~~~~~~~~~~~~~~

Ref: http://fasterdata.es.net/

These scripts were developed for high-speed transfer of telescope and
pulsar data from remote and other-capital sites to Perth.

Note that fdtPut7.sh was upgraded 20090804 so as to transfer batches of files
instead of individual files; when tested with "-b 32" this gave a 15 times
performance increase in local VPAC tests.  It's performance is still only
about 30% of that delivered by "gloPut7.sh -u".

Also note that gloPut8.sh was instantiated 20090902 on recommendation of
developers .. uses '-rst' for stall detection.  Doesn't work in practise!

GKJ-20090902

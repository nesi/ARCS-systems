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

On 20090908, gloPut7.sh was enhanced so as to detect SIGUSR1 and SIGUSR2
for on-the-fly switching between TCP and UDT modes.

On 20090929, gloPut7.sh was further enhanced by replacing the progressive
kill function with 'kill -9', and adding a kill-zombie-parents capability.

On 20091006, gloPut7t.sh and gloPut7r.sh were introduced. These use a computed
time-limit value fed to globus-url-copy instead of a log-watch timing loop,
and are less likely to create zombies and hang. gloPut7r.sh does a recursive
copy of files which changed in the last 299 days.

On 20091229, gloPut7T.sh and gloPut7R.sh were introduced; these use the
stall-timeout parameter available in Globus-5. gloPut7z.sh was also
introduced; this is a version of gloPut7T.sh modified through the
inclusion of a Zombie-manager capability.

On 20091230, gloPut7R.sh was simplified by removal of the create-subdirectories 
section; it now relies on the "-cd" parameter for globus-url-copy for this.

On 20100125, STALL and POLLING_THREADS things were removed from both
gloPut7T.sh and gloPut7R.sh ..

On 20100330, a number of superseded scripts were removed from this directory;
many of the problems referenced above have been addressed by gridftp-killer,
and it is expected that this may not be required after the introduction of
GT 5.0.1 ..

On 20100405, gloPut7T.sh was enhanced through the use of filename/size
couplets in a sorted list; this made it both shorter and faster.

GKJ-20100405

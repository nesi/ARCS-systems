import os
import string

handle = os.popen("iqstat -a")
output = string.join(handle.readlines())
handle.close()
print output
splits = output.split()
num = [a for a in splits if splits.index(a) % 2 == 0]
for n in num:
    handle = os.popen("iqdel " + n)
    print "closing " + n
    handle.close()

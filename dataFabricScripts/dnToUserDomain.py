#!/usr/bin/env python

import sys, os

def parse_dn(dn):
    """
    Parse DN into a dict of arrays
    """
    res={}
    for item in dn.split('/')[1:]:
            res[item.split('=')[0]] = item.split('=')[1]
    print res
    return res


def getUsername(user,O):
	if O == 'ARCS':
		user = user.split(' ')[:-1]
		username = ''
		for string in user:
			username += string.lower()
		return username
	else:
		return user.replace(' ','').lower()

domains = {
    'iVEC':'srb.ivec.org',
    'JCU':'srb.ivec.org',
    'SAPAC':'srb.ivec.org'
    }

if __name__ == '__main__':
	f = open ('/tmp/output','a')
	f.write(str(sys.argv))
	f.close()
	if len(sys.argv) == 2:
		exe, dn = sys.argv
		comp = parse_dn(dn)
		if domains.has_key(comp['OU'][0]):
			user = "%s@%s"%(getUsername(comp['CN'][0],comp['O'][0]),domains[comp['OU'][0]])
			print user

	else:
		print "dnToUserDomain.py <dn>"

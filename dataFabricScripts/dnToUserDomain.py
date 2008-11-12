#!/usr/bin/env python

#------------------------------------------------------------------
# 03-11-2008: change script so that it will not recognise
#             slcstest certificates.  Also restrict 
#             username length to 35
#             Also making sure if a user in the same domain has
#             the same name.  If so, will suffix the name with a 
#             psuedo random number (no longer than 3 characters)
#------------------------------------------------------------------
import sys, os, random

def parse_dn(dn):
	"""
	Parse DN into a dict of arrays
	"""
	res={}
        for item in dn.split('/')[1:]:
                res[item.split('=')[0]] = item.split('=')[1]
	return res

def checkLength(user, username):
    if(len(username) < 36):
        return username
    else:
        newUsername = ''
        for str in user[:-1]:
            newUsername += str.toLower()[0] + "."
        newUsername += user[-1:]
        if(len(username) < 36):
            return newUsername
        else:
            #Hopefully, user cannot logon, and bug the data team...
            "Cannot generate an appropriate username"
            return None

def checkExisting(username, domain):
    if(username == None):
        return None
    lines = os.popen("SgetU " + username + "*@" + domain).readlines()
    if(len(lines) == 0):
        return username
    else:
        newName = name
        lines = lines.filter(
        names = map(lambda x: x[:], lines)
        while not (newName in names):
            newName = username + `random.randint(0, 999)`
        return newName

def getUsernameSlcs1(user, dn, domain):
    #the DC stuff has to be at the start of the string??
    if(dn.find('/DC=au/DC=org/DC=arcs/DC=slcs') == 0):
        user = user.split(' ')[:-1]
        username = ''
        for string in user:
            username += string.lower()
        username = checkLength(user, username)
        username = checkExisting(username, domain)
        return username
    else:
        return user.replace(' ','').lower()

domains = {
    'TPAC':'srbdev.sf.utas.edu.au',
    }

if __name__ == '__main__':
    f = open ('/tmp/output','a')
    f.write(str(sys.argv))
    f.close()
    if len(sys.argv) == 2:
        exe, dn = sys.argv
        comp = parse_dn(dn)
        if(comp.has_key('DC') and domains.has_key(comp['O'])):
            user = "%s@%s"%(getUsernameSlcs1(comp['CN'],dn,domains[comp['O']),domains[comp['O']])
            if(user <> None):   
                print user
    else:
        print "dnToUserDomain.py <dn>"

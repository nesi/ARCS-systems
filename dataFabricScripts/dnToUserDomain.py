#!/usr/bin/env python

#------------------------------------------------------------------
# 03-11-2008: change script so that it will not recognise
#             slcstest certificates.  Also restrict 
#             username length to 35
#             Also making sure if a user in the same domain has
#             the same name.  If so, will suffix the name with a 
#             psuedo random number (no longer than 3 characters)
# 26-11-2008: Bug fixes courtesy of Vlad :)  The script is now
#             free of debug statements, can handle misformatted
#             DNs and also cope with noraml X509 DNs.  It also
#             accepts the BeSTGRID DN.
#------------------------------------------------------------------
import sys, os
import popen2
from DNCONFIG import *

def parse_dn(dn):
	"""
	Parse DN into a dict of arrays
	"""
	res={}
        for item in dn.split('/')[1:]:
                res[item.split('=')[0]] = item.split('=')[1]
	return res

def checkLength(user, username, domain):
    if(len(username + "@" + domain) < 36):
        return username
    else:
        newUsername = ''
        newUsername = reduce(lambda x, y: x + "." +  y, map(lambda x: x[0].lower(), user[:-1]))
        newUsername = newUsername + "." + user[-1].lower()
        if(len(newUsername + "@" + domain) < 36):
            return newUsername
        else:
            print "Cannot generate an appropriate username"
            return None

def checkExisting(username, domain):
    if(username == None):
        return None
    (output, input, error) = popen2.popen3("/usr/bin/SgetU " + username + "*@" + domain + " | grep user_name")
    errorLines = error.readlines()
    error.close()
    input.close()
    if((len(errorLines) > 0) and ((errorLines[0].find('SgetR Error: -3005') == 0))):
        return username
    else:
        lines = output.readlines()
        output.close()
        newName = username
        names = map(lambda x: x[11:-1], lines)
        count = 1
        while (newName in names):
            newName = username + `count`
            count = count + 1
        if(len(newName + "@" + domain) > 35):
            #give up - the name is too long
            return None
        return newName

def isSlcs1(dn):
    if( ((dn.find('/DC=au') >= 0) and (dn.find('/DC=arcs') >= 0)) or 
        ((dn.find('/DC=nz') >= 0) and (dn.find('/DC=bestgrid') >= 0)) ):
        if((dn.find('/DC=org') >= 0) and (dn.find('/DC=slcs') >= 0)):
            return True
    return False

def isApacGridCA(dn):
    if( ((dn.find('/C=AU') >= 0) and (dn.find('/O=APACGrid') >= 0)) or 
        ((dn.find('/C=NZ') >= 0) and (dn.find('/O=BeSTGRID') >= 0)) ):
        return True
    return False

def getUsername(user, dn, domain):
    #the DC stuff has to be at the start of the string??
    if(isSlcs1(dn) or isApacGridCA(dn)):
        if(isSlcs1(dn)):
            user = user.split(' ')[:-1]
        else:
            user = user.split(' ')
        username = ''
        for string in user:
            username += string.lower()
        username = checkLength(user, username, domain)
        #username = checkExisting(username, domain)
        return username
    else:
        return None


if __name__ == '__main__':
    f = open ('/tmp/output','a')
    f.write(str(sys.argv)+"\n")
    f.close()
    if len(sys.argv) == 2:
        exe, dn = sys.argv
        comp = parse_dn(dn)
        username = None
        if(comp.has_key('DC') and domains.has_key(comp['O'])):
            username = getUsername(comp['CN'],dn,domains[comp['O']])
            domain = domains[comp['O']]
        if(comp.has_key('O') and comp.has_key('OU') and domains.has_key(comp['OU'])):
            username = getUsername(comp['CN'],dn,domains[comp['OU']])
            domain = domains[comp['OU']]
	if(username <> None):
	    print username + "@" + domain
    else:
        print "dnToUserDomain.py <dn>"


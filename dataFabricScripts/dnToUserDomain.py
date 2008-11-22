#!/usr/bin/env python

#------------------------------------------------------------------
# 03-11-2008: change script so that it will not recognise
#             slcstest certificates.  Also restrict 
#             username length to 35
#             Also making sure if a user in the same domain has
#             the same name.  If so, will suffix the name with a 
#             psuedo random number (no longer than 3 characters)
#------------------------------------------------------------------
import sys, os
import popen2

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
        newUsername = newUsername + "." + user[-1]
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
    if((dn.find('/DC=au') >= 0) and (dn.find('/DC=arcs') >= 0)):
        if((dn.find('/DC=org') >= 0) and (dn.find('/DC=slcs') >= 0)):
            return True
    return False
    
def getUsernameSlcs1(user, dn, domain):
    #the DC stuff has to be at the start of the string??
    if(isSlcs1(dn)):
        user = user.split(' ')[:-1]
        username = ''
        for string in user:
            username += string.lower()
        username = checkLength(user, username, domain)
        #username = checkExisting(username, domain)
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
            username = getUsernameSlcs1(comp['CN'],dn,domains[comp['O']])
            domain = domains[comp['O']]
            if(username <> None):
                print username + "@" + domain
    else:
        print "dnToUserDomain.py <dn>"


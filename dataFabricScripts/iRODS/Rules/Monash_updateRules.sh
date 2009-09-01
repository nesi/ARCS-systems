#!/bin/sh
# updateRules.sh	Downloads Monash-specific rules files for iRODS; should
#			be invoked periodically via 'cron'.
#			Graham Jenkins <graham@vpac.org> Sep. 2009; Rev 20090901
# 
#                       NOTE: This version was supplied to Monash staff for
#                       subsequent maintenance by them.

# Usage, destination directory
[ -z "$1" ] && ( echo "Usage: `basename $0` default-resource"
                 echo " e.g.: `basename $0` laards.monash.edu.au") >&2 && exit 2

# 'fail' function.  Usage: fail "log-message"
fail () {
  logger -t "iRODs-Rules-Download" "$@" && exit 1
}

# 'getfile' function.  Usage: getfile remote-name local-name
getfile () {         # Note:  wget uses revision-no to force proxy-cache reload
  rm -f $2                                             || fail "File removal failed!"
  wget -O $2 \
    http://vera010.its.monash.edu.au/svn/merc/iRODS/${1}"?q=$$" 2>/dev/null &
  sleep 10
  kill $! 2>/dev/null                                  && fail "Timed out!"
  [ -s $2 ] && return 0                                || return 1
}

# Change to destination directory
[ -n "$IRODS_HOME" ] && cd "$IRODS_HOME" 2>/dev/null || cd `dirname $0`/../../.. 2>/dev/null
cd server/config/reConfigs 2>/dev/null               || fail "Directory change failed!" 

# If there's a new version of this program, install it and exit
getfile updateRules.sh _SCRATCH
if [ -s _SCRATCH ] ; then
  Des="`cd ../../bin/local && pwd`"
  if ! cmp _SCRATCH "$Des"/updateRules.sh >/dev/null 2>&1 ; then
    chmod a+rx _SCRATCH && exec mv -f "$PWD"/_SCRATCH "$Des"/updateRules.sh
  fi
fi

# Determine Zone, select rules filename extension accordingly
Zone="`cat ~/.irods/.irodsEnv 2>/dev/null | awk '/^irodsZone/ {print \$2;exit}' | tr -d /\\'/`" 
case "$Zone" in
  monash    ) Extn=".irb"                          ;;
  monashzone) Extn="zone.irb"                      ;;
  *         ) fail "Unknown or indeterminate zone!";;
esac

# Get files and edit as appropriate, then exit
for File in monash ; do
  getfile "$File""$Extn" _SCRATCH                                      || continue
  [ "$File" = "monash" ] && sed -i -e "s/DEFAULT_RESOURCE/$1/g" _SCRATCH
  mv -f _SCRATCH "$File".irb 2>/dev/null                               || fail "Bad rename!"
done
rm -f _SCRATCH
exit 0

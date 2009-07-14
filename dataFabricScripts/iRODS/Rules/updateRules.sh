#!/bin/sh
# updateRules.sh	Downloads ARCS-specific rules files for iRODS; should
#			be invoked periodically via 'cron'.
#			Graham Jenkins <graham@vpac.org> Mar 2009; Rev 20090714


# Usage, destination directory
[ -z "$1" ] && ( echo "Usage: `basename $0` default-resource"
                 echo " e.g.: `basename $0` arcs-df.vpac.org") >&2 && exit 2

# 'fail' function.  Usage: fail "log-message"
fail () {
  logger -t "iRODs-Rules-Download" "$@" && exit 1
}

# 'getfile' function.  Usage: getfile remote-name local-name
getfile () {
  rm -f $2                                             || fail "File removal failed!"
  wget -O $2 \
    http://projects.arcs.org.au/svn/systems/trunk/dataFabricScripts/iRODS/Rules/$1 2>/dev/null &
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
  ARCS      ) Extn=".irb"                          ;;
  ARCSDEV   ) Extn="dev.irb"                       ;;
  ARCSTEST  ) Extn="test.irb"                      ;;
  ARCSEXTRA ) Extn="extra.irb"                     ;;
  *         ) fail "Unknown or indeterminate zone!";;
esac

# Get files and edit as appropriate, then exit
for File in arcs imos ; do
  getfile "$File""$Extn" _SCRATCH                                      || continue
  [ "$File" = "arcs" ] && sed -i -e "s/DEFAULT_RESOURCE/$1/g" _SCRATCH
  mv -f _SCRATCH "$File".irb 2>/dev/null                               || fail "Bad rename!"
done
exit 0

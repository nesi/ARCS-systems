#!/bin/sh
# gloMan7T.sh  Manages Globus Certificate-based Third-party directory copy.
#              Graham.Jenkins@arcs.org.au  Dec. 2010. Rev: 20101231

# Environment; adjust as appropriate
for Dir in globus-5 globus-5.0.1 globus-5.0.2 globus-4.2.1; do
  [ -d "/opt/$Dir/bin" ] && GLOBUS_LOCATION=/opt/$Dir && break
done
PATH=$GLOBUS_LOCATION/bin:$PATH
export GLOBUS_LOCATION PATH

# Usage, ssh parameters
Match="."
while getopts srm: Option; do
  case $Option in
    s) Skip="Y";;
    r) Order="-r";;
    m) Match=$OPTARG;;
   \?) Bad="Y";;
  esac
done
shift `expr $OPTIND - 1`
[ \( -n "$Bad" \) -o \( $# -ne 2 \) ] &&
  ( echo "  Usage: `basename $0` source-path destination-path"
    echo "   e.g.: `basename $0` xen-d.vpac.org/tmp/Source/" \
                                "pbstore.ivec.org/tmp/Destin/"
    echo "Options: -s        .. skip files whose names begin with a period"
    echo "         -m String .. send only files whose names contain 'String'"
    echo "         -r        .. reverse order"                   ) >&2 && exit 2

echo "Generating a list of files to be copied .. wait .."
for File in `globus-url-copy -list gsiftp://$1/ | tr -d "\000" | 
             awk '{if(NF>0) if($1!~"/") print $1}' |grep $Match|sort $Order`; do
  case "`basename $File`" in
      .* ) [ -n "$Skip" ] && continue ;;
  esac
  echo -n "`date '+%a %T'` .. $File .. "
  if globus-url-copy -q -cd -fast gsiftp://$1/$File gsiftp://$2/ ; then
    echo OK
  else
    echo Failed; sleep 5
  fi
done

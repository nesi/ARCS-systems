#!/bin/bash

# initial sanity check
[ -z "$GLOBUS_LOCATION" ] && { echo "please set the GLOBUS_LOCATION environment variable"; exit 1; }


# success/warning/failure
RETVAL=0
#trap "let 'RETVAL = RETVAL + 1'" ERR

function set_status() {
	[ "$1" -gt "$RETVAL" ] && RETVAL=$1
}

# if anything fails up to the 'globusrun-ws' stuff, we bail
set -o errexit

function usage() {
	cat <<-EOF
		usage: $0 [-g gateway_hostname] [-r gridftp_base] [-m Fork|PBS] [-h]

		-h	show usage
		-g	hostname of gateway to connect to (defaults to $DEF_HOSTNAME)
		-f	hostname for staging gridftp server (must be mapped/mounted to local filesystem. eg: ng2.your.domain - defaults to $DEF_FTP)
		-m	which jobmanager to use, Fork or PBS (defaults to $DEF_JOBMANAGER)
	EOF
}


# default argument setup and sanity check
DEF_HOSTNAME="$(hostname -f)"
DEF_OUTDIR="$(pwd)/test_results_$$"
DEF_FTP="$DEF_HOSTNAME"
DEF_GATEWAY="$DEF_HOSTNAME"
DEF_JOBMANAGER="Fork"

while getopts "hf:g:m:" OPTION; do
	case $OPTION in
		h) usage; exit 0;;
		f) FTP=$OPTARG;;
		g) GATEWAY=$OPTARG;;
		m) JOBMANAGER=$OPTARG;;
		*) usage; exit 1;;
	esac
done

# set provided options
HSTNAME="${HSTNAME:-$DEF_HOSTNAME}"
GATEWAY="${GATEWAY:-$DEF_GATEWAY}"
JOBMANAGER="${JOBMANAGER:-$DEF_JOBMANAGER}"
OUTDIR="${OUTDIR:-$DEF_OUTDIR}"
FTP="${FTP:-$DEF_FTP}"


# globus/grid init stuff
source $GLOBUS_LOCATION/etc/globus-user-env.sh
if ! grid-proxy-info -e; then
	grid-proxy-init
fi


# careful here - must have correct indenting in xml and appropriate labels
BASE_XML_1="$(sed -ne '/^##base_xml_1/,/##end_base_xml_1/ p' $0 | sed -ne '2,/^<\// p')"
BASE_XML_2="$(sed -ne '/^##base_xml_2/,/##end_base_xml_2/ p' $0 | sed -ne '2,/^<\// p')"
JOB_1="job_1.xml"
JOB_2="job_2.xml"


# create needed files/directories
[ ! -d "$OUTDIR" ] && mkdir -p $OUTDIR
sed -ne "/^##test_script_1/,/^##end_test_script_1/ p" $0 | sed -ne "2,$ p" > $OUTDIR/test_script_1
sed -ne "/^##test_script_2/,/^##end_test_script_2/ p" $0 | sed -ne "2,$ p" > $OUTDIR/test_script_2

pushd $OUTDIR
MESSAGE="You can find the input/output for these test in $OUTDIR"

chmod +x test_script_1
chmod +x test_script_2
eval echo "\"$BASE_XML_1\"" > $JOB_1
eval echo "\"$BASE_XML_2\"" > $JOB_2


# let's get it on
echo -e "\n$MESSAGE\n"
# we want to run all these tests?
set +e

set -x

globusrun-ws -submit -Ft $JOBMANAGER -F https://$GATEWAY:8443/wsrf/services/ManagedJobFactoryService -S -f $JOB_1
set_status $?

globusrun-ws -submit -Ft $JOBMANAGER -F https://$GATEWAY:8443/wsrf/services/ManagedJobFactoryService -s -f $JOB_2
set_status $?

set +x
popd


echo
if [ "$RETVAL" -eq 0 ]; then # gold
	cat <<-EOF
		SUCCESS!

		These tests have succeeded.  Congratulations.

		$MESSAGE
	EOF

elif [ "$RETVAL" -eq 1 ]; then # warnings only
	[ -f "$OUTDIR/stderr" ] && MESSAGE="$MESSAGE
You should have a look at $OUTDIR/stderr."

	cat <<-EOF
		WARNING

		At least some of these tests produced warnings.

		$MESSAGE
	EOF

else
	[ -f "$OUTDIR/stderr" ] && MESSAGE="$MESSAGE
You should definitely have a look at $OUTDIR/stderr."

	cat <<-EOF
		FAILURE

		At least some of these tests failed.

		$MESSAGE
	EOF
fi

# so we don't try and run anything else
exit $RETVAL

### END OF EXECUTABLE SCRIPT



##base_xml_1
<job>
	<executable>test_1</executable>
	<directory>\${GLOBUS_USER_HOME}</directory>
	<argument>output_file</argument>
	<stdout>\${GLOBUS_USER_HOME}/stdout</stdout>
	<stderr>\${GLOBUS_USER_HOME}/stderr</stderr>
	<fileStageIn>
		<transfer>
			<sourceUrl>gsiftp://$FTP:2811/$OUTDIR/test_script_1</sourceUrl>
			<destinationUrl>file:///\${GLOBUS_USER_HOME}/test_1</destinationUrl>
		</transfer>
	</fileStageIn>
	<fileStageOut>
		<transfer>
			<sourceUrl>file:///\${GLOBUS_USER_HOME}/output_file</sourceUrl>
			<destinationUrl>gsiftp://$FTP:2811/$OUTDIR/output_file</destinationUrl>
		</transfer>
		<transfer>
			<sourceUrl>file:///\${GLOBUS_USER_HOME}/stdout</sourceUrl>
			<destinationUrl>gsiftp://$FTP:2811/$OUTDIR/stdout</destinationUrl>
		</transfer>
		<transfer>
			<sourceUrl>file:///\${GLOBUS_USER_HOME}/stderr</sourceUrl>
			<destinationUrl>gsiftp://$FTP:2811/$OUTDIR/stderr</destinationUrl>
		</transfer>
	</fileStageOut>
	<fileCleanUp>
		<deletion>
			<file>file:///\${GLOBUS_USER_HOME}/test_1</file>
		</deletion>
		<deletion>
			<file>file:///\${GLOBUS_USER_HOME}/stderr</file>
		</deletion>
		<deletion>
			<file>file:///\${GLOBUS_USER_HOME}/stdout</file>
		</deletion>
		<deletion>
			<file>file:///\${GLOBUS_USER_HOME}/output_file</file>
		</deletion>
	</fileCleanUp>
</job>
##end_base_xml_1


##base_xml_2
<job>
	<executable>test_2</executable>
	<directory>\${GLOBUS_USER_HOME}</directory>
	<argument>\${GLOBUS_USER_HOME}/test_1</argument>
	<argument>\${GLOBUS_USER_HOME}/stdout</argument>
	<argument>\${GLOBUS_USER_HOME}/stderr</argument>
	<argument>\${GLOBUS_USER_HOME}/output_file</argument>
	<fileStageIn>
		<transfer>
			<sourceUrl>gsiftp://$FTP:2811/$OUTDIR/test_script_2</sourceUrl>
			<destinationUrl>file:///\${GLOBUS_USER_HOME}/test_2</destinationUrl>
		</transfer>
	</fileStageIn>
	<fileCleanUp>
		<deletion>
			<file>file:///\${GLOBUS_USER_HOME}/test_2</file>
		</deletion>
	</fileCleanUp>
</job>
##end_base_xml_2


##test_script_1
#!/bin/sh

OUTPUT_FILE=$1

echo "test starting: $@" > $OUTPUT_FILE

RETVAL=0

function log() {
	echo "LOG: $@"
	echo "LOG: $@" >> $OUTPUT_FILE
}

function warn() {
	log "$@"
	echo "WRN: $@" >&2
	[ "$RETVAL" -lt 2 ] && RETVAL=1
}

function err() {
	log "$@"
	echo "ERR: $@" >&2
	RETVAL=2
}


hostname || warn "problem running hostname"

VARIABLES="GLOBUS_USER_NAME"
FS_VARIABLES="HOME GLOBUS_USER_HOME GLOBUS_SCRATCH_DIR USER_SCRATCH NODE_SCRATCH"

for i in $VARIABLES; do
	if [ -z "${!i}" ]; then
		err "variable $i not defined"
	else
		log "$i: ${!i}"
	fi
done
for i in $FS_VARIABLES; do
	if [ -z "${!i}" ]; then
		err "variable $i not defined"
	else
		log "$i: ${!i}"

		if [ ! -d "${!i}" ]; then
			err "${!i} is not a directory"
			if ! mkdir -p ${!i}; then
				err "${!i} could not be created"
			else
				MSG="${!i} could be created, maybe you should do this yourself?"
				warn "$MSG"
				rmdir ${!i}
			fi
		else
			log "${!i} is a directory"
			if touch ${!i}/test_$$; then
				log "${!i} is writable"

				# individual extra tests
				case $i in
					NODE_SCRATCH)
						FSTYPE="$(stat -f -c %T ${!i}/test_$$)"
						case $FSTYPE in
							ext*|reiser*|xfs*)
								log "$i (${!i}) is on a local filesystem ($FSTYPE)" ;;
							*)
								warn "$i (${!i}) is not on a local filesystem ($FSTYPE)" ;;
						esac ;;
					USER_SCRATCH|HOME)
						FSTYPE="$(stat -f -c %T ${!i}/test_$$)"
						case $FSTYPE in
							ext*|reiser*|xfs*)
								warn "$i (${!i}) is on a local filesystem ($FSTYPE)" ;;
							*)
								log "$i (${!i}) is not on a local filesystem ($FSTYPE)" ;;
						esac ;;
					*) ;;
				esac

				rm -f ${!i}/test_$$
			else
				err "${!i} is not writable"
			fi
		fi
	fi
done

# I think this check might be worth something
if [ "$GLOBUS_USER_HOME" != "$HOME" ]; then
	warn "GLOBUS_USER_HOME and HOME aren't the same: $GLOBUS_USER_HOME vs $HOME"
fi

# a quick modules test
if MODULE_OUT="$(module avail 2>&1)"; then
	echo "$MODULE_OUT" >> $OUTPUT_FILE
else
	err "problem listing modules: $MODULE_OUT"
fi

echo "test finished with result $RETVAL" >> $OUTPUT_FILE

exit $RETVAL

##end_test_script_1


##test_script_2
#!/bin/bash

FILES="$*"

for i in $FILES; do
	[ -e $i ] && exit 2
done

exit 0

##end_test_script_2




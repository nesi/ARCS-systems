#!/bin/bash


# keep a count of mishaps
RETVAL=0
trap "let 'RETVAL = RETVAL + 1'" ERR

# if anything fails up to the 'globusrun-ws' stuff, we bail
set -o errexit

function usage() {
	cat <<-EOF
		usage: $0 [-g gateway_hostname] [-m Fork|PBS] [-h]

		-h	show usage
		-m	hostname of gateway to connect to (defaults to current hostname)
		-g	which jobmanager to use, Fork or PBS (defaults to Fork)
	EOF
}


# default argument setup and sanity check
HOSTNAME="$(hostname -f)"
OUTDIR="test_results_$$"
GATEWAY="$HOSTNAME"
JOBMANAGER="Fork"
while getopts "hg:m:" OPTION; do
	case $OPTION in
		h) usage; exit 0;;
		g) GATEWAY=$OPTARG;;
		m) JOBMANAGER=$OPTARG;;
		*) usage; exit 1;;
	esac
done

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
RESULTS_DIR="$PWD"
MESSAGE="You can find the input/output for these test in $RESULTS_DIR"
chmod +x test_script_1
chmod +x test_script_2
eval echo "\"$BASE_XML_1\"" | sed -e "s/%HOSTNAME%/$HOSTNAME/g" > $JOB_1
eval echo "\"$BASE_XML_2\"" | sed -e "s/%HOSTNAME%/$HOSTNAME/g" > $JOB_2


# let's get it on
echo -e "\n$MESSAGE\n"
# we want to run all these tests?
set +e

set -x
globusrun-ws -submit -Ft $JOBMANAGER -F https://$GATEWAY:8443/wsrf/services/ManagedJobFactoryService -S -f $JOB_1
globusrun-ws -submit -Ft $JOBMANAGER -F https://$GATEWAY1:8443/wsrf/services/ManagedJobFactoryService -s -f $JOB_2
set +x
popd


echo
if [ "$RETVAL" -eq 0 ]; then # gold
	cat <<-EOF
		SUCCESS!

		These tests have succeeded.  Congratulations.

		$MESSAGE
	EOF
else
	[ -f "$RESULTS_DIR/stderr" ] && MESSAGE="$MESSAGE
You should especially have a look at $RESULTS_DIR/stderr."

	cat <<-EOF
		FAILURE

		At least some of these tests have failed.

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
			<sourceUrl>gsiftp://%HOSTNAME%:2811/$PWD/test_script_1</sourceUrl>
			<destinationUrl>file:///\${GLOBUS_USER_HOME}/test_1</destinationUrl>
		</transfer>
	</fileStageIn>
	<fileStageOut>
		<transfer>
			<sourceUrl>file:///\${GLOBUS_USER_HOME}/output_file</sourceUrl>
			<destinationUrl>gsiftp://%HOSTNAME%:2811/$PWD/output_file</destinationUrl>
		</transfer>
		<transfer>
			<sourceUrl>file:///\${GLOBUS_USER_HOME}/stdout</sourceUrl>
			<destinationUrl>gsiftp://%HOSTNAME%:2811/$PWD/stdout</destinationUrl>
		</transfer>
		<transfer>
			<sourceUrl>file:///\${GLOBUS_USER_HOME}/stderr</sourceUrl>
			<destinationUrl>gsiftp://%HOSTNAME%:2811/$PWD/stderr</destinationUrl>
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
			<sourceUrl>gsiftp://%HOSTNAME%:2811/$PWD/test_script_2</sourceUrl>
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

echo "test starting" > output_file

RETVAL=0

function log() {
	echo "LOG: $@"
	echo "LOG: $@" >> output_file
}

function warn() {
	echo "WRN: $@" >&2
}

function err() {
	echo "ERR: $@" >&2
}

function warn_log() {
	log $@
	warn $@
	increment_err
}

function err_log() {
	log $@
	err $@
	increment_err
}

function increment_err() {
	let "RETVAL = RETVAL + 1"
}

/bin/hostname || increment_err

VARIABLES="GLOBUS_USER_NAME"
FS_VARIABLES="HOME GLOBUS_USER_HOME GLOBUS_SCRATCH_DIR USER_SCRATCH NODE_SCRATCH"

for i in $VARIABLES; do
	if [ -z "${!i}" ]; then
		err_log "variable $i not defined"
	else
		log "$i: ${!i}"
	fi
done
for i in $FS_VARIABLES; do
	if [ -z "${!i}" ]; then
		err_log "variable $i not defined"
	else
		log "$i: ${!i}"

		if [ ! -d "${!i}" ]; then
			err_log "${!i} is not a directory"
			if ! mkdir -p ${!i}; then
				err_log "${!i} could not be created"
			else
				MSG="${!i} could be created, maybe you should do this yourself?"
#				log "$MSG"
				warn_log "$MSG"
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
								warn_log "$i (${!i}) is not on a local filesystem ($FSTYPE)" ;;
						esac ;;
					USER_SCRATCH|HOME)
						FSTYPE="$(stat -f -c %T ${!i}/test_$$)"
						case $FSTYPE in
							ext*|reiser*|xfs*)
								warn_log "$i (${!i}) is on a local filesystem ($FSTYPE)" ;;
							*)
								log "$i (${!i}) is not on a local filesystem ($FSTYPE)" ;;
						esac ;;
					*) ;;
				esac

				rm -f ${!i}/test_$$
			else
				err_log "${!i} is not writable"
			fi
		fi
	fi
done

# I think this check might be worth something
if [ "$GLOBUS_USER_HOME" != "$HOME" ]; then
	err_log "GLOBUS_USER_HOME and HOME aren't the same: $GLOBUS_USER_HOME vs $HOME"
fi

# a quick modules test
if MODULE_OUT="$(module avail 2>&1)"; then
	echo "$MODULE_OUT" >> output_file
else
	err_log "problem listing modules: $MODULE_OUT"
fi

echo "test finished" >> output_file

exit $RETVAL

##end_test_script_1


##test_script_2
#!/bin/bash

FILES="$*"

for i in $FILES; do
	[ -e $i ] && exit 1
done

exit 0

##end_test_script_2




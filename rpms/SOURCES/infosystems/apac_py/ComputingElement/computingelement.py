#!/usr/bin/env python

# $ARGV[0] = clustername
# $ARGV[1] = uid from apac.pl
# $ARGV[2] = MIP config dir

import os, sys
import apac_lib as lib
import os.path, new

def minutes(pbs_time):
	(hours, minutes, seconds) = map(int, pbs_time.split(":"))
	return hours * 60 + minutes

def parseLLTime(lltimeStr): # return type: seconds
  # parsing "[days+]hours:mins:secs.fractsect
  # 5+08:11:40.966084
  # 02:00:00 (7200 seconds)
    #sys.stderr.write("parsing LL time : %s\n" % lltimeStr)
    if lltimeStr.find('+')>0:
        (days,lltimeStr) = lltimeStr.split('+')
	days = int(days)
    else:
        days = 0

    (hours, minutes, seconds) = map(int, lltimeStr.split(":"))

    totalseconds = seconds+60*(minutes+60*(hours+24*days))
    #sys.stderr.write("totalseconds : %d\n" % totalseconds)
    
    return totalseconds


def processNodeInfo(node_info, ce, filterArg):
	try:
		from nodeFilter import filter
		if not filter(node_info, filterArg):
			return
		
	except Exception, e:
		sys.stderr.write("error running node filter: %s\n" % e)

	if not 'state' in node_info:
		return

	if 'down' in node_info['state'] or 'offline' in node_info['state']:
		return

	if config.LRMSType == "PBSPro":
		np = int(node_info['resources_available.ncpus'][0])
	else: # we'll assume that everything will use openpbs or torque
		np = int(node_info['np'][0])
	ce.TotalCPUs += np
	ce.FreeCPUs += np

	if node_info.has_key('jobs'):
		ce.FreeCPUs -= len(node_info['jobs'])

def processLLNodeInfo(llnode_info, ce):

	#print llnode_info.items();
	if not 'Name' in llnode_info:
		return
        if (llnode_info['StartdAvail'] == 0):
                return
        if (not (llnode_info['Machine Mode'].startswith( 'batch' ) or llnode_info['Machine Mode'].startswith( 'general' ) )):
                return

	import re
	class_expr = re.compile(r"^(\S+)\((\d+)\)")

	nodeClsAvailCPUs = None;

	# AvailableClasses is empty when node is full, use ConfiguredClasses
	# instead
	for clsStr in llnode_info['ConfiguredClasses'].split(' '):
		matchO = class_expr.match(clsStr);
		if matchO is None:
		   return
		results = matchO.groups();
		if len(results) == 2 : 
		  clsName,nrFree = results[0], results[1]
		  if clsName.startswith(config.Name) and config.Name.startswith(clsName):
		     nodeClsAvailCPUs=nrFree
	#print "Node %s nodeClsAvailCPUs=%s" % ( llnode_info['Name'], nodeClsAvailCPUs)
	if (nodeClsAvailCPUs is None):
	   return

	#np = int(llnode_info['Cpus'])
        # for SMP nodes, Max_Starters matches what LoadLeveler will allow
	np = int(llnode_info['Max_Starters'])
	ce.TotalCPUs += np
	ce.FreeCPUs += np

        #sys.stderr.write("found %d cpus\n" % np)

	if llnode_info.has_key('Running Tasks'):
		ce.FreeCPUs -= int(llnode_info['Running Tasks'])
        #sys.stderr.write("%d cpus are busy\n" % int(llnode_info['Running Tasks']))

#	for key, value in node_info.items():
#		print "%s: %s" % (key, value)


if __name__ == '__main__':

	#sys.stderr.write('in the computing element calculation\n')

	c = lib.read_config(sys.argv[3])

	lib.assert_contains(c, sys.argv[1])
	lib.assert_contains(c[sys.argv[1]], 'ComputingElement')
	lib.assert_contains(c[sys.argv[1]].ComputingElement, sys.argv[2])

	config = c[sys.argv[1]].ComputingElement[sys.argv[2]]

	ce = lib.ComputingElement()
	ce.users = []

	ce.isBlueGene = "isBlueGene" in config.__dict__ and config.isBlueGene == True

	# caclculate the number of cpus and free cpus, ie ce.TotalCPUs and ce.FreeCPUs
	if config.LRMSType == "Torque" or config.LRMSType == "PBSPro":
		#sys.stderr.write('in the Torque / PBSPro number of cpus section\n')
		if config.pbsnodes is not None and os.path.isfile(config.pbsnodes):
			ce.TotalCPUs = 0
			ce.FreeCPUs = 0

			filterArg = None
			if hasattr(config, 'nodePropertyFilter'):
				filterArg = config.nodePropertyFilter

			node_info = {}

			lines = lib.run_command([config.pbsnodes, '-a'])
			for line in lines:
				if not line:
					processNodeInfo(node_info, ce, filterArg)
					node_info = {}
					continue

				values = line.split('=')
				if len(values) == 1:
					node_info['name'] = values[0]
				else:
					node_info[values[0].strip()] = [v.strip() for v in values[1].split(",")]
	elif config.LRMSType == "OpenPBS":
		#sys.stderr.write('in the ANUPBS number of cpus section\n')
		if config.qstat is not None and os.path.isfile(config.qstat):
                        # WARNING - this requires config.HostName to be the PBS server (not the grid gateway)
			lines = lib.run_command([config.qstat, '-B', '-f', config.HostName])

			for line in lines:
				#sys.stderr.write('line is : ' + line + '\n')
				if line.startswith('resources_available.ncpus'):
					#sys.stderr.write('matched line to resources_available' + '\n')
					ce.TotalCPUs = int(line.split()[-1])
					#sys.stderr.write('total cpus is calculated to be ' + str(ce.TotalCPUs) + '\n')
				if line.startswith('resources_assigned.ncpus'):
					# assumes that TotalCPUs always appears first in the command
					#sys.stderr.write('matched line to resources_assigned' + '\n')
					ce.FreeCPUs = ce.TotalCPUs - int(line.split()[-1])

	elif config.LRMSType == "LoadLeveler":
	# caclculate the number of cpus and free cpus, ie ce.TotalCPUs and ce.FreeCPUs
		#sys.stderr.write('in the LoadLeveler number of cpus section\n')
		if config.llstatus is not None and os.path.isfile(config.llstatus):
                    if ce.isBlueGene:
			lines = lib.run_command([config.llstatus, '-b', '-l'])
                        import re
			ce.TotalCPUs = 0
			ce.FreeCPUs = 0
			bgRE = re.compile(r"^\s*Total\s+Blue\s+Gene\s+Compute\s+Nodes\s+(\d+)\s*$")
			for line in lines:
			  bgMatch = bgRE.match(line)
			  if (bgMatch is not None and len(bgMatch.groups())==1):
                             # First, get the total number of BlueGene nodes
			     ce.TotalCPUs = ce.FreeCPUs = int(bgMatch.groups()[0])

                        # now get the list of all allocated BG partitions and subtract the nodes from FreeCPUs
                        # Get the raw llq output with BlueGene size (for all running jobs)
			lines = lib.run_command([config.llq, '-r', '%BS'])
			bgJobSizeRE = re.compile(r"^(\d+)$")
			for line in lines:
			  bgMatch = bgJobSizeRE.match(line)
			  if (bgMatch is not None and len(bgMatch.groups())==1):
			     ce.FreeCPUs = ce.FreeCPUs - int(bgMatch.groups()[0])

                        # now, scale the numbers by CPUs per node
                        CPUsPerNode = 1
                        if "BG_CPUsPerNode" in config.__dict__:
                            CPUsPerNode = config.BG_CPUsPerNode;
                        ce.TotalCPUs = ce.TotalCPUs * CPUsPerNode;
                        ce.FreeCPUs = ce.FreeCPUs * CPUsPerNode;

			ce.AssignedJobSlots = ce.TotalCPUs # may be overriden by Maximum_slots:
                        if "MaxCPUsVisible" in config.__dict__:
                            if ce.TotalCPUs > config.MaxCPUsVisible:
                                ce.TotalCPUs = config.MaxCPUsVisible
                            if ce.FreeCPUs > config.MaxCPUsVisible:
                                ce.FreeCPUs = config.MaxCPUsVisible
                    else:
			ce.TotalCPUs = 0
			ce.FreeCPUs = 0

			lines = lib.run_command([config.llstatus, '-l'])

			llnode_info = {}
			for line in lines:
				if line.startswith('====') :
					processLLNodeInfo(llnode_info, ce)
					llnode_info = {}
					continue

				values = line.split('=')
				if (len(values)>1):
				    llnode_info[values[0].strip()] = values[1].strip();
			processLLNodeInfo(llnode_info, ce);
			ce.AssignedJobSlots = ce.TotalCPUs # may be overriden by Maximum_slots:
                
	# caclculate the number of cpus and free cpus, ie ce.TotalCPUs and ce.FreeCPUs
	elif config.LRMSType == "SGE":
		#sys.stderr.write('in the SGE number of cpus section\n')
		if config.qstat is not None and os.path.isfile(config.qstat):
			ce.TotalCPUs = 0
			ce.FreeCPUs = 0

                        # invoke: qstat -g c -q medium64
			# expect:
			# CLUSTER QUEUE                   CQLOAD   USED    RES  AVAIL  TOTAL aoACDS  cdsuE  
			# --------------------------------------------------------------------------------
			# medium64                          0.37     29      0     48     88      0     12 

			lines = lib.run_command([config.qstat, '-g', 'c', '-q', config.Name])
			if (len(lines) == 3):
			        values = lines[2].split();
				# indexes: 2:usedCPUs, 3:reserved, 4:avail, 5:total, 6:down1, 7:down2
				ce.TotalCPUs = int(values[5]) - (int(values[6])+int(values[7]))
				ce.FreeCPUs = int(values[4]);
		                #sys.stderr.write("SGE qstat -g c -q done: TotalCPUs=%d, FreeCPUs=%d\n" % (ce.TotalCPUs, ce.FreeCPUs))
	else:
		# do nothing, the LRMS type is not understood
		pass
		
	# get information about the queues and the running jobs
	if config.LRMSType == "Torque" or config.LRMSType == "PBSPro" or config.LRMSType == "OpenPBS":
		if config.qstat is not None and os.path.isfile(config.qstat):
                        # WARNING - this requires config.HostName to be the PBS server (not the grid gateway)
			lines = lib.run_command([config.qstat, '-B', '-f', config.HostName])

			for line in lines:
				if line.startswith('pbs_version'):
					ce.LRMSVersion = line.split()[-1]


			lines = lib.run_command([config.qstat, '-Q', '-f', config.Name])

			import socket
			hostname = socket.getfqdn()

			do_host_acl = do_user_acl = True
			user_acl_done = enabled = started = False

			for line in lines:
				if line.startswith("queue_type ="):
					if not line.split()[-1] == "Execution":
						print "Not execution queue"
						break
				elif line.startswith("acl_host_enable ="):
					if not line.split()[-1] == "True":
						do_host_acl = False
				elif line.startswith("acl_users_enable ="):
					if not line.split()[-1] == "True":
						do_user_acl = False
				elif line.startswith("acl_hosts = ") and do_host_acl:
					allowed = False
					for name in line.split("=")[1].strip().split(","):
						if name == hostname:
							allowed = True
						# wildcard
						elif hostname.endswith(name.split("*")[-1]):
							allowed = True
					# this host isn't allowed to submit!
					if not allowed:
						pass
						# wipe
#						ce = lib.ComputingElement()
#						break
				elif line.startswith("acl_users = ") and do_user_acl:
					for name in line.split("=")[1].strip().split(","):
						ce.users.append(name)
					user_acl_done = True
				elif line.startswith("enabled = "):
					if line.split()[-1] == "True":
						enabled = True
				elif line.startswith("started = "):
					if line.split()[-1] == "True":
						started = True
				elif line.startswith("max_queuable ="):
					ce.MaxTotalJobs = line.split()[-1]
				elif line.startswith("total_jobs ="):
					ce.TotalJobs = line.split()[-1]
				elif line.startswith("Priority = "):
					ce.Priority = int(line.split()[-1])
				elif line.startswith("max_running = "):
					ce.MaxRunningJobs = int(line.split()[-1])
				elif line.startswith("max_user_run = "):
					ce.MaxTotalJobsPerUser = int(line.split()[-1])
				elif line.startswith("resources_max.cput = "):
					ce.MaxCPUTime = minutes(line.split()[-1])
				elif line.startswith("resources_max.walltime = "):
					ce.MaxWallClockTime = minutes(line.split()[-1])
				elif line.startswith("state_count ="):
					ce.WaitingJobs = 0
					entries = line.split()
					for index in [3, 4, 5]:
						ce.WaitingJobs += int(entries[index].split(":")[-1])

					ce.RunningJobs = int(entries[6].split(":")[-1])

				elif line.startswith("resources_max.ncpus = "):
					ce.resources_max_ncpus = int(line.split()[-1])
				
			if enabled and started:
				# no user acl processing done, grab the list of users from the vo map
				# TODO: hmmm, this work is questionable
				# it just copies from the config to an emtpy VOView!
				ce.ACL = config.ACL
				if not user_acl_done and len(config.views) > 0:

					for viewkey in config.views.keys():
						view = lib.VOView()
						
						# note: now copying also ApplicationDir, but it
						# will get overwritten by ce.ApplicationDir
						for key in ('DefaultSE', 'DataDir', 'RealUser', 'ApplicationDir'):
							if config.views[viewkey].__dict__[key] is not None:
								view.__dict__[key] = config.views[viewkey].__dict__[key]

						if len(config.views[viewkey].ACL) > 0:
							view.ACL = config.views[viewkey].ACL
							ce.ACL += view.ACL

						ce.views[viewkey] = view

				for viewkey in ce.views.keys():
					view = ce.views[viewkey]
					view.ApplicationDir = ce.ApplicationDir
					view.TotalJobs = 0
					view.RunningJobs = 0
					view.WaitingJobs = 0

					if view.RealUser is not None:

						lines = lib.run_command([config.qstat, '-u', view.RealUser, config.Name])

						import re

						select_expr = re.compile(r"^\d+")
						running_expr = re.compile(r"\d+\s+[RE]\s+")
						waiting_expr = re.compile(r"\d+\s+[QHTW]\s+")

						for line in lines:
							if select_expr.match(line):
								view.TotalJobs += 1
								if running_expr.search(line):
									view.RunningJobs += 1
								elif waiting_expr.search(line):
									view.WaitingJobs += 1

					view.FreeJobSlots = ce.FreeCPUs
					# voview's freejob slots should be maxtotaljobsperuser - running jobs (not totaljobs)
					#if ce.MaxTotalJobsPerUser and ce.FreeCPUs > ce.MaxTotalJobsPerUser - view.TotalJobs:
					#	view.FreeJobSlots = ce.MaxTotalJobsPerUser - view.TotalJobs
					if ce.MaxTotalJobsPerUser and ce.FreeCPUs > ce.MaxTotalJobsPerUser - view.RunningJobs:
						view.FreeJobSlots = ce.MaxTotalJobsPerUser - view.RunningJobs

	# LoadLeveler: get information about the queues and the running jobs

	# simplifying assumptions:
	#  - no host/user ACLs
	#  - queues are always started/enabled

	# extracting: 
	#   current job status from llq -c class
	#   max walltime, priority, free slots, total slots from llclass -l 
	if config.LRMSType == "LoadLeveler":
		if config.llq is not None and os.path.isfile(config.llq):

			# get version information
			lines = lib.run_command([config.llq, '-version'])
			for line in lines:
				if line.startswith('llq'):
					ce.LRMSVersion = " ".join(line.split()[1:])

			import re
			jobsRE = re.compile("^(\d+) job step\D+(\d+) waiting, (\d+) pending, (\d+) running, (\d+) held, (\d+) preempted")
                        # note: this RE is also used later to get per VO information
			
			#lines = lib.run_command([config.llq, '-c',config.Name])
                        # we want overall job stats, not just one class
                        # Nope, it's really better to check only within the class
                        # Better then getting the same results for all classes

			# Initialize everything with zero - if we don't get a
			# match, it means there's no job in this class and all
			# these should be zero.
                        ce.TotalJobs = ce.WaitingJobs = ce.RunningJobs = 0
			lines = lib.run_command([config.llq, '-c', config.Name])
			for line in lines:
			  jobsMatch = jobsRE.match(line)
			  if jobsMatch is not None:
			    jobsResults=jobsMatch.groups()
			    if len(jobsResults) == 6:
			      #sys.stderr.write("parsed line %s\n" % line)
			      ce.TotalJobs    = int(jobsResults[0]); # total
			      ce.WaitingJobs  = int(jobsResults[1]); # waiting
			      ce.RunningJobs  = int(jobsResults[3]); # running
			      ce.RunningJobs += int(jobsResults[2]); # pending
			      ce.WaitingJobs += int(jobsResults[4]); # held
			      ce.WaitingJobs += int(jobsResults[5]); # preempted
			    

		if config.llclass is not None and os.path.isfile(config.llclass):

		    lines = lib.run_command([config.llclass, '-l', '-c', config.Name])

		    enabled = started = False

		    for line in lines:
			line=line.strip()
			line_value = line[line.find(':')+1:].strip()
			# Maxjobs has the meaning of "max running jobs",
			# but it's not clear for what.  In the output of
			# llclass -l, it would be meaning of Max Running
			# Jobs in this class - which OK, matches Max
			# Running Jobs for this CE.  
			#
			# We have to look at it differently in VOView,
			# where MaxRunning for this user would match
			# Maxjobs.
			# I still don't know how to get user's Maxjobs...
			#
			# For the CE, let MaxRunning be MaxJobs (-1 on HPC)
			# and let's leave PerUser undefined
			if line.startswith("Maxjobs:") and int(line_value) is not -1:
			    ce.MaxRunningJobs = int(line_value)
			    # there's likely no value for MaxTotalJobs
			elif line.startswith("Maximum_slots:") and int(line_value) is not -1 and not ce.isBlueGene:
			    ce.AssignedJobSlots = int(line_value)
			elif line.startswith("Free_slots:") and int(line_value) is not -1 and not ce.isBlueGene:
			    ce.FreeJobSlots = int(line_value)
			elif line.startswith("Priority:") and int(line_value) is not -1:
			    ce.Priority = int(line_value)
			elif line.startswith("Wall_clock_limit:"):
			    wallRE = re.compile(r"^([^\s,]+),\s+([^\s,]+)\s+")
			    wallMatch = wallRE.match(line_value)
			    if (wallMatch is not None and len(wallMatch.groups())==2):
                                wallSoftMax = parseLLTime(wallMatch.groups()[0])/60
                                wallHardMax = parseLLTime(wallMatch.groups()[1])/60

                                # if both limits are specified, use the lower - otherwise use the limit we have
                                if wallSoftMax>0 and wallHardMax>0:
				    ce.MaxWallClockTime = min(wallSoftMax, wallHardMax)
                                elif wallHardMax>0:
				    ce.MaxWallClockTime = wallHardMax
                                elif wallsoftMax>0:
				    ce.MaxWallClockTime = wallsoftMax
			elif line.startswith("Job_cpu_limit:") and not line_value.startswith("undefined"):
			    ce.MaxCPUTime = parseLLTime(line_value.split(",")[0])/60

		ce.ACL = config.ACL
		for viewkey in config.views.keys():
		    view = lib.VOView()
		    
		    # note: now copying also ApplicationDir, but it
		    # will get overwritten by ce.ApplicationDir
		    for key in ('DefaultSE', 'DataDir', 'RealUser', 'ApplicationDir'):
			if config.views[viewkey].__dict__[key] is not None:
			    view.__dict__[key] = config.views[viewkey].__dict__[key]

		    if len(config.views[viewkey].ACL) > 0:
			    view.ACL = config.views[viewkey].ACL
			    ce.ACL += view.ACL

		    ce.views[viewkey] = view

		for viewkey in ce.views.keys():
		    view = ce.views[viewkey]
		    view.ApplicationDir = ce.ApplicationDir
		    view.TotalJobs = 0
		    view.RunningJobs = 0
		    view.WaitingJobs = 0

		    if view.RealUser is not None and config.llq is not None and os.path.isfile(config.llq):

			view.TotalJobs = view.WaitingJobs = view.RunningJobs = 0

			lines = lib.run_command([config.llq, '-u', view.RealUser, '-c', config.Name])
			# jobsRE already defined earlier
			for line in lines:
			  jobsMatch = jobsRE.match(line)
			  if jobsMatch is not None:
			    jobsResults=jobsMatch.groups()
			    if len(jobsResults) == 6:
			      view.TotalJobs    = int(jobsResults[0]); # total
			      view.WaitingJobs  = int(jobsResults[1]); # waiting
			      view.RunningJobs  = int(jobsResults[3]); # running
			      view.RunningJobs += int(jobsResults[2]); # pending
			      view.WaitingJobs += int(jobsResults[4]); # held
			      view.WaitingJobs += int(jobsResults[5]); # preempted

		    view.FreeJobSlots = ce.FreeCPUs
		    # There is no way we can tell how many CPUs
		    # (JobSlots) the user is allowed to use.
		    # In LoadLEveler, this would be capped by
		    # max_total_tasks, but this is not used in
		    # our setting.  Hence, just pass
		    # ce.FreeCPUs as view.FreeJobSlots
		    ###if config.MaxTotalRunningJobsPerUser and ce.FreeCPUs > config.MaxTotalRunningJobsPerUser - view.RunningJobs:
		    ###     view.FreeJobSlots = config.MaxTotalRunningJobsPerUser - view.RunningJobs

	if config.LRMSType == "SGE":
		if config.qstat is not None and os.path.isfile(config.qstat):
			# Get LRMS version: get the first line of "qstat -help"
			lines = lib.run_command([config.qstat, '-help'])
			if ((len(lines)>=1) and lines[0]):
			        ce.LRMSVersion = lines[0];

			# Get various limits associated with a queue
			# qconf -sq medium64
			#
			# Interesting bits:
			# s_rt                  INFINITY
			# h_rt                  240:00:00
			# s_cpu                 INFINITY
			# h_cpu                 228:00:00
			# Is it soft/hard runtime(walltime)/cput limits? In HH:MM:SS ?
			lines = lib.run_command([config.qconf, '-sq', config.Name])

			for line in lines:
				values = line.split(None, 1)
				if (values[0] == "s_rt" or values[0] == "h_rt") and (values[1] != "INFINITY"): 
					rt_limit = minutes(values[1])
					if (ce.MaxWallClockTime is None) or (rt_limit < ce.MaxWallClockTime):
					        ce.MaxWallClockTime = rt_limit
				if (values[0] == "s_cpu" or values[0] == "h_cpu") and (values[1] != "INFINITY"): 
					cpu_limit = minutes(values[1])
					if (ce.MaxCPUTime is None) or (cpu_limit < ce.MaxCPUTime):
					        ce.MaxCPUTime = cpu_limit
				if (values[0] == "priority") and (values[1] != "NONE"): 
					ce.Priority = int(values[1])
				# not populating: ce.MaxTotalJobsPerUser, ce.MaxRunningJobs

			# Get the queue utilization now
			# Pending(Running+Held)+Suspended jobs with: qstat -s ps -q <qname> -u "*"
			# Running jobs with: qstat -s r -q <qname> -u "*"
			# If the output has >=2 lines, the number of jobs is len(lines)-2
			# For empty output, the number of jobs is 0.
			ce.WaitingJobs = 0
			ce.RunningJobs = 0

			lines = lib.run_command([config.qstat, '-s', 'ps', '-q', config.Name, '-u', '*'])
			if len(lines) >=2:
			        ce.WaitingJobs = len(lines)-2

			lines = lib.run_command([config.qstat, '-s', 'r', '-q', config.Name, '-u', '*'])
			if len(lines) >=2:
			        ce.RunningJobs = len(lines)-2

			ce.TotalJobs = ce.WaitingJobs + ce.RunningJobs

			# grab the list of users from the vo map
			# TODO: hmmm, this work is questionable
			# it just copies from the config to an emtpy VOView!

			for viewkey in config.views.keys():
				view = lib.VOView()
				
				# note: now copying also ApplicationDir, but it
				# will get overwritten by ce.ApplicationDir
				for key in ('DefaultSE', 'DataDir', 'RealUser', 'ApplicationDir'):
					if config.views[viewkey].__dict__[key] is not None:
						view.__dict__[key] = config.views[viewkey].__dict__[key]

				if len(config.views[viewkey].ACL) > 0:
					view.ACL = config.views[viewkey].ACL
					ce.ACL += view.ACL

				ce.views[viewkey] = view

			for viewkey in ce.views.keys():
				view = ce.views[viewkey]
				view.ApplicationDir = ce.ApplicationDir
				view.TotalJobs = 0
				view.RunningJobs = 0
				view.WaitingJobs = 0

				if view.RealUser is not None:

					lines = lib.run_command([config.qstat, '-s', 'ps', '-q', config.Name, '-u', view.RealUser])
					if len(lines) >=2:
						view.WaitingJobs = len(lines)-2
					lines = lib.run_command([config.qstat, '-s', 'r', '-q', config.Name, '-u', view.RealUser])
					if len(lines) >=2:
						view.RunningJobs = len(lines)-2
					view.TotalJobs = view.WaitingJobs + view.RunningJobs

				view.FreeJobSlots = ce.FreeCPUs
				# voview's freejob slots should be maxtotaljobsperuser - running jobs (not totaljobs)
				#if ce.MaxTotalJobsPerUser and ce.FreeCPUs > ce.MaxTotalJobsPerUser - view.TotalJobs:
				#	view.FreeJobSlots = ce.MaxTotalJobsPerUser - view.TotalJobs
				if ce.MaxTotalJobsPerUser and ce.FreeCPUs > ce.MaxTotalJobsPerUser - view.RunningJobs:
					view.FreeJobSlots = ce.MaxTotalJobsPerUser - view.RunningJobs

# TODO: in pbs.pl $jobs{MaxTotalJobsPerUser} is always undefined!
#					$jobs{FreeJobSlots}=$queues{$myqueue}{MaxTotalJobsPerUser}-$jobs{TotalJobs} if defined $jobs{MaxTotalJobsPerUser} and defined $jobs{TotalJobs};
#					conf.user_info.__dict__[user].FreeJobSlots = cp.MaxTotalJobsPerUser - conf.user_info.__dict__[user].TotalJobs


	# overridable values
	for key in ['JobManager', 'ApplicationDir', 'DataDir', 'DefaultSE', 'ContactString', 'Status', 'HostName', 'GateKeeperPort', 'Name', 'LRMSType', 'LRMSVersion', 'GRAMVersion', 'TotalCPUs', 'FreeCPUs', 'RunningJobs', 'FreeJobSlots', 'TotalJobs', 'Priority', 'WaitingJobs']:
		if config.__dict__[key] is not None:
			ce.__dict__[key] = config.__dict__[key]

	# only override the Max* attributes if they are less than the default
	for key in ['MaxWallClockTime', 'MaxCPUTime', 'MaxRunningJobs', 'MaxTotalJobs']:
		if config.__dict__[key] is not None and config.__dict__[key] < ce.__dict__[key]:
			ce.__dict__[key] = config.__dict__[key]


        # VM: minor change: do not recalculate FreeJobSlots if it is already set (leave it as # of CPUs available)
	if ce.MaxTotalJobs is not None and ce.TotalJobs is not None and ce.FreeJobSlots is None:
		ce.FreeJobSlots = int(ce.MaxTotalJobs) - int(ce.TotalJobs)

        # reduce FreeJobSlots if FreeCPUs (From a different calculation) is less
	if ce.FreeCPUs < ce.FreeJobSlots or ce.FreeJobSlots is None:
		ce.FreeJobSlots = ce.FreeCPUs

	# print
	for key in ['JobManager', 'ApplicationDir', 'DataDir', 'DefaultSE', 'ContactString', 'Status', 'HostName', 'GateKeeperPort', 'Name', 'LRMSType', 'LRMSVersion', 'GRAMVersion', 'TotalCPUs', 'FreeCPUs', 'MaxWallClockTime', 'MaxCPUTime', 'RunningJobs', 'FreeJobSlots', 'MaxRunningJobs', 'MaxTotalJobs', 'TotalJobs', 'Priority', 'WaitingJobs']:
		if ce.__dict__[key] is not None:
			print "<%s>%s</%s>" % (str(key), str(ce.__dict__[key]), str(key))


	for viewkey in ce.views.keys():
		view = ce.views[viewkey]

		print "<VOView LocalID=\"%s\">" % viewkey

		for key in ('FreeJobSlots', 'TotalJobs', 'RunningJobs', 'WaitingJobs', 'DefaultSE', 'ApplicationDir', 'DataDir'):
			if view.__dict__[key] is not None:
				print "\t<%s>%s</%s>" % (key, view.__dict__[key], key)

		print "\t<ACL>"
		for rule in view.ACL:
			print "\t\t<Rule>%s</Rule>" % rule
		print "\t</ACL>"
		print "</VOView>"

	print "<ACL>"
	for rule in set(ce.ACL):
		print "\t<Rule>%s</Rule>" % rule
	print "</ACL>"


#!/usr/bin/env python

"""
The script is a tool for removing some old srb log files because of ever-increasing number of log files that are created based on interval(days). 
The default interval is 5 days. 
"""
import datetime, glob, getopt, os, string, sys, tarfile

today = datetime.date.today()

def fetch_files(pattern, search_path, pathsep = os.pathsep):

    for path in search_path.split(pathsep):
        for match in glob.glob(os.path.join(path, pattern)):
              yield match

def sort_files(file_list):

    filename = ''
    files_dict = {}
    for match in file_list:
        path_seg = match.split('/')[5]
        seg = path_seg.split('.')
        month = seg[1]
        day = seg[2]
        if len(seg[3]) < 2: year = "200"+seg[3]
        elif len(seg[3]) < 3: year = "20"+seg[3]   
        elif len(seg[3]) < 4: year = "2"+seg[3]
        else: filedate3 = seg[3]  
        date1 = datetime.date(int(year), int(month), int(day))
        if today == date1: diff = 1
        else:
           diff_1 = str(today - date1) 
           diff = int(diff_1[0]+diff_1[1]) + 1
        files_dict[diff] = match 
    keys = files_dict.keys()
    keys.sort()
    return [files_dict[key] for key in keys]

def process_files(count, file_list, action):
    
    timestamp = datetime.datetime.now().strftime("%y-%m-%d %H:%M:%S")
    if action == 1: 
       for name in file_list[count:]:
            print '[' + timestamp+'] ' + name + ' is removed'
            os.remove(name)

    elif action == 2:
       print '\nA list of SRB log files is displayed as follows:\n'
       for name in file_list[0:]:     
            print  name 
       print '\nThe total number of SRB log files is: ' +str(len(file_list))+'\n'

    else:
       if not os.path.exists('/usr/srb/data/log/bak'):
            os.system('mkdir /usr/srb/data/log/bak')
       tarname = '/usr/srb/data/log/bak/'+ 'srbLog.' + str(today)+'.tar'
       tar = tarfile.open(tarname, "w:tar")
       for name in file_list[count:]:
           print '[' + timestamp+'] ' + name + ' is compressed' 
           tar.add(name)
       tar.close()

def usage():
    usage = ["\n     python LogsCleanup.py -k N -d \n"]
    usage.append ("         [-k | --keep] Set how many log files are kept - A value of 5 for N means that you will keep last 5 log files \n")
    usage.append ("         [-d | --delete] Delete all the log files but for the last N log files \n")
    usage.append ("         [-l | --list] Print a list of current SRB log files \n")
    usage.append ("         [-h | --help] Print a short usage summary \n")

    message = string.join(usage)
    print message

def main():

    logdir = "/usr/srb/data/log"
    file = 'srbLog.*'
    fList = {}
    numFiles = 0
    ops = 0

    try:
        options, args = getopt.getopt(sys.argv[1:], "hk:ld", ["help", "keep", "list", "delete="])
    except getopt.GetoptError, err:
        # will print something like "option -a not recognized"
        print str(err)
        # print help information and exit:
        usage()
        sys.exit()
        
    if len(options) ==0 : 
        sys.exit('Please use the option -k to specify the number of log files that you want to keep') 
    
    for o, a in options:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-k", "--keep"):
            try:
               numFiles = int(sys.argv[2])
            except:
               sys.exit('Must provide a valid number!')
        elif o in ("-l", "--list"):
            ops = 2
        elif o in ("-d", "--delete"):
            ops = 1
        else:
            assert False, "unhandled option"

    matches = list(fetch_files(file, logdir))
    fList = sort_files(matches)
    if ops == 2: 
         process_files(numFiles, fList, ops)
         sys.exit()
    if numFiles in range(1, len(matches)):
         process_files(numFiles, fList, ops)
    elif numFiles == len(matches):
         sys.exit('No log files needs to be cleaned up!')
    else:
         if ops == 2: process_files(numFiles, fList, ops)
         else: sys.exit("Must provide one number between 1 and " + str(len(matches)))

if __name__ == "__main__": 
   sys.exit(main())


#!/usr/bin/env python

"""
The script is a tool for removing some old srb log files because of ever-increasing number of log files that are created based on interval(days). The default interval is 
5 days. 
"""
import datetime, glob, getopt, os, string, sys, tarfile, time

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
        today = datetime.date.today()
        diff_1 = str(today - date1) 
        diff = int(diff_1[0]+diff_1[1]) + 1
        files_dict[diff] = match 
    keys = files_dict.keys()
    keys.sort()
    return [files_dict[key] for key in keys]

def process_files(count, file_list, action):

    if action == 1: 
       for name in file_list[count:]:
            print name
            os.remove(name)
    else:
       today = datetime.date.today()
       if not os.path.exists('/usr/srb/data/log/bak'):
            os.system('mkdir /usr/srb/data/log/bak')
       tarname = '/usr/srb/data/log/bak/'+ 'srbLog.' + str(today)+'.tar.bz2'
       tar = tarfile.open(tarname, "w:bz2")
       for name in file_list[count:]:
            print name
            tar.add(name)
       tar.close()

def usage():
    usage = ["          LogsCleanup.py -k Value - a positive number \n"]
    usage.append ("         [-k | --keep] Set how many log files are kept - A value of 5 means that you will keep recent 5 log files \n")
#   usage.append ("         [-c | --compress] Compress the old log files - DEFAULT \n")
#   usage.append ("         [-d | --delete]  Delete the old log files \n")
    usage.append ("         [-h | --help]  Print a short usage summary \n")

    message = string.join(usage)
    print message

def main():

    logdir = "/usr/srb/data/log"
    file = 'srbLog.*'
    fList = {}
    numFiles = 0
    ops = 0

    try:
        options, args = getopt.getopt(sys.argv[1:], "hk:cdv", ["help", "keep", "compress", "delete="])
    except getopt.GetoptError, err:
        print str(err)
        # print help information and exit:
        usage()
        # will print something like "option -a not recognized"
        sys.exit()
        
    if len(options) ==0 : 
        sys.exit('Please use the argument -k to specify the number of log files that you want to keep') 
    
    for o, a in options:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-k", "--keep"):
            try:
               numFiles = int(sys.argv[2])
            except:
               sys.exit('Must provide a valid number!')
#        elif o in ("-c", "--compress"):
#            print 'compress'
#        elif o in ("-d", "--delete"):
#             ops = 1
#             print 'delete'
        else:
            assert False, "unhandled option"

    if numFiles < 0:  # negative integer
        sys.exit("Must provide one positive number!")
    matches = list(fetch_files(file, logdir))
    fList = sort_files(matches)
    process_files(numFiles, fList, ops)

if __name__ == "__main__": 
   sys.exit(main())


'''Run the tests simultaneously in different processes.'''

import os
from subprocess import Popen
import time

ps = []

def get_num_running():
    x = 0
    for p in ps:
        if p.poll() is None:
            x += 1
    return x

n_tests = 39
max_processes = 13
for i in range(n_tests):
    while (get_num_running() >= max_processes):  # wait to start new ones
        time.sleep(10)
    os.system('rm -rf ../top-{}'.format(i))
    os.system('cp -r ../top ../top-{}'.format(i))
    os.chdir('../top-{}'.format(i))
    args = 'make PLUSARGS="+test_num={}"'.format(i).split()
    print('Starting child with args: ', args)
    f = open('../top-{}/test_log.txt'.format(i), 'w')
    ps.append(Popen(args, stdout=f, stderr=f))

    for i in range(len(ps)):
        if ps[i].poll() is not None:
            print('process {} finished'.format(i))

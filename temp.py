import os
import glob
import time
from decimal import *
getcontext().prec = 3

os.system('modprobe w1-gpio')
os.system('modprobe w1-therm')
 
base_dir = '/sys/bus/w1/devices/'

temp0 = 32.0
temp1 = 32.0
#temps = temp0 + temp1

for f in range(2):
	device_folder = glob.glob(base_dir + '28*')[f]
	device_file = device_folder + '/w1_slave'
 
	def read_temp_raw():
	    f = open(device_file, 'r')
	    lines = f.readlines()
	    f.close()
	    return lines
 
	def read_temp():
	    lines = read_temp_raw()
	    while lines[0].strip()[-3:] != 'YES':
	        time.sleep(0.2)
	        lines = read_temp_raw()
	    equals_pos = lines[1].find('t=')
	    if equals_pos != -1:
	        temp_string = lines[1][equals_pos+2:]
	        temp_c = round(float(temp_string) / 1000.0, 2)
	        temp_f = round(temp_c * 9.0 / 5.0 + 32.0, 2)
	        return temp_f
    	
	if f == 0:
		temp0 = read_temp()
#		print "Temp 0: ", temp1 # See note below about having to swap
	else:
		temp1 = read_temp()
#  		print "Temp 1: ", temp0 # See note below about having to swap
		
# Open the file to write temps to 
f = open('/var/www/kegtemps.txt', 'w')
# I had to swap the values here so they'd be in the right order according to the board.
f.write('{0},{1}\n'.format(temp1,temp0))

# Close the file
f.close()

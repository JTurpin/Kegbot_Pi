import time
import serial

ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)

while 1:
  # read from the serial device
  s = ser.readline()
  
  # if there is nothing read, move on to the next iteration of the loop
  if len(s) == 0:
    continue
  # Create a list from the serial input
  s = s.rstrip();
  i = s.split(',')

  print i;
  # check to see that we have all the values from the serial device
#  if len(i) < 4:
#    print "noise?";
#    continue
  
  # Open the file for reading then to write (hence the r+)
  f = open('/var/www/kegstats.txt', 'r+')
  # Read in the file so we can do some processing on the last 2 columns
  line = f.readline()
  #print line;

  # Create another list from the kegstats text file
  o = line.split(',')
  #print o;

  # Set the new temprature
  o[0:2] = i[0:2]

  # Update counts
  o[2] = int(o[2]) - int(i[2])
  o[3] = int(o[3]) - int(i[3])

  # Write the string to a file for delivering via apache
  # set the pointer back to the beginning of the file prior to writing it.
  f.seek(0);
  f.write(','.join(map(str,o)))

  # Close the file
  f.close()

import csv
import time
import serial

ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)

while 1:
#line = ser.readline()   # read a '\n' terminated line
#       s = ser.readline();


        # Define the string as Variable s
        s = "#,87.12,76.77,0,0";
        #print s;
        # find out if # is in the string
        #if s.find("#") == -1:
                # We found the right string with #
                #    print "__"
                # The string doesn't contain a #
        #else:
        #    print "__"

        # Let's clean up our string here to remove the #,
        s = s.replace("#,", "");
        print s
        # now we split it into seperate vars
        itemp1, itemp2, ikeg1, ikeg2 = s.split(',')
        #Open the file
        f = open('kegstats.txt');
        # Read in the file so we can do some processing on the last 2 columns
        line = f.read()
        line = line.rstrip()
        #print line;
        # Do our math on the last two columns
        otemp1, otemp2, okeg1, okeg2 = line.split(',')

        o1 = int(ikeg1) - int(okeg1)
        o2 = int(ikeg2) - int(okeg2)
        output = str(itemp1)+str(",")+str(itemp2)+str(",")+str(o1)+str(",")+str(o2)

        # Write the string to a file for delivering via apache
        #f.write(output)

        # Close the file
        f.close()

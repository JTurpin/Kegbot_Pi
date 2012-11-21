#!/usr/bin/env python

import time
import serial
# Import some necessary libraries.
import socket, ssl

# Some basic variables used to configure the bot        
server = "bajafur.atrust.com" # Server
port = 6697 # Port
channel = "#seal" # Channel
botnick = "KegBot" # Your bots nick

def ping(): # This is our first function! It will respond to server Pings.
  ircsock.send("PONG :pingis\n")

def sendmsg(chan , msg): # This is the send message function, it simply sends messages to the channel.
  ircsock.send("PRIVMSG "+ chan +" :"+ msg +"\n")

def joinchan(chan): # This function is used to join channels.
  ircsock.send("JOIN "+ chan +"\n")

def hello(): # This function responds to a user that inputs "Hello Mybot"
  ircsock.send("PRIVMSG "+ channel +" :Hello!\n")

i = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
i.connect((server, port)) # Here we connect to the server using the port 6697
ircsock = ssl.wrap_socket(i)
ircsock.send("USER "+ botnick +" "+ botnick +" "+ botnick +" :This bot is a result of a tutoral covered on http://shellium.org/wiki") # user authentication
ircsock.send("NICK "+ botnick +"\n") # here we actually assign the nick to the bot
joinchan(channel) # Join the channel using the functions we previously defined

ser = serial.Serial(port='/dev/ttyUSB0', baudrate=56700, bytesize=8, parity='N', stopbits=1, timeout=1)
from time import sleep
sleep(5)

while 1:
  # read from the serial device
  s = ser.readline()

  ircmsg = ircsock.recv(2048) # receive data from the server
  ircmsg = ircmsg.strip('\n\r') # removing any unnecessary linebreaks.
  #print(ircmsg) # Here we print what's coming from the server

  if ircmsg.find(":Hello "+ botnick) != -1: # If we can find "Hello Mybot" it will call the function hello()
    hello()

  if ircmsg.find("PING :") != -1: # if the server pings us then we've got to respond!
    ping()
  
  # if there is nothing read, move on to the next iteration of the loop
  if len(s) == 0:
    continue
  # Create a list from the serial input
  s = s.rstrip();
  i = s.split(',')
 
  # Bubble Management goes right here 
  if(i[2] > 15):
	i[2] == 0;
  if(i[3] > 15):
	i[3] == 0;
  
  # lets talk some shit in the chat room
#  if(i[2] > 125 or i[3] > 125)
	# we need to track and make sure that we're not reporting multiple times for a single pour
	
	# then we talk shit
	#msg = "Someone is pouring a beer!";
	#sendmsg(channel, msg)	
	
  from time import localtime, strftime
  print i, strftime("%a, %d %b %Y %H:%M:%S +0000", localtime());
  
  # Open the file for reading then to write (hence the r+)
  f = open('/var/www/kegstats.txt', 'r+')
  # Read in the file so we can do some processing on the last 2 columns
  line = f.readline()
 
  #print line;
  line = line.strip()
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
  f.seek(0)
  
  # Truncate everything after the current file position (which should be
  # everything on the line
  f.truncate()
  
  # Everything has been updated in our list, let's join each item together
  # with a comma after mapping each item in the list (o) as a string.
  f.write(','.join(map(str,o)))

  # Close the file
  f.close()

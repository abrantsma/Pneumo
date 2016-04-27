import time
import sys
import os
import RPi.GPIO as GPIO
from spit_bitbang_testv2 import avgADC

### Initialize Space
GPIO.setmode(GPIO.BOARD)
GPIO.cleanup()

### Choose MUX pins
# 16:1 MUX
A0_16 = 37
A1_16 = 35
A2_16 = 33
A3_16 = 31
EN_16 = 29

# 4:1 MUX
A0_4 = 40
A1_4 = 38
EN_4 = 36

# 2:1 MUX
EN_2

### Setup MUX
MUX = [16,4,2]
for i in range(4):
  GPIO.setup(eval('A'+str(i)+'_16'),GPIO.OUT)
for i in range(2):
  GPIO.setup(eval('A'+str(i)+'_4'),GPIO.OUT)
for i in range(3):
  GPIO.setup(eval('EN_'+str(MUX[i])),GPIO.out)

### Initialize ADC
GPIO.setup(15,GPIO.OUT)
GPIO.setup(21,GPIO.IN)
GPIO.setup(22,GPIO,out)
GPIO.setwarnings(False)

### Function
# Function for hangling logic for switching pins
# Input: electrrode we want to turn on (1 index)
def switch_pin(electrode):
  # Initialize by inhibiting everything
  MUX = [16,4,2]
  for i in range(2):
    GPIO.output(eval('EN_'+str(MUX[i])),GPIO.LOW)
  
  if (electrode<=0 or electrode>20):
    return 'Error. Electrode must be between 1 and 20'
  # Logic for the 16:1 MUX  
  elif (electrode>0 and electrode<=16):
    GPIO.output(EN_16,GPIO.HIGH)
    GPIO.output(EN_2,GPIO.HIGH)
    if (electrode%2==0):
      GPIO.output(A0_16,GPIO.HIGH)
    else:
      GPIO.output(A0_16,GPIO.LOW)
    A1_high_list = [3,4,7,8,11,12,15,16]
    if (electrode in A1_high_list):
      GPIO.output(A1_16,GPIO.HIGH)
    else:
      GPIO.output(A1_16,GPIO.LOW)
    A2_high_list = [5,6,7,8,13,14,15,16]
    if (electrode in A2_high_list):
      GPIO.output(A2_16,GPIO.HIGH)
    else:
      GPIO.output(A2_16,GPIO.LOW)
    A3_high_list = [9,10,11,12,13,14,15,16]
    if (electrode in A3_high_list):
      GPIO.output(A3_16,GPIO.HIGH)
    else:
      GPIO.output(A3_16,GPIO.LOW)
  
  # Logic for the 4:1 MUX
  elif (electrode>16 and electrode<=20):
    GPIO.output(EN_4,GPIO.HIGH)
    GPIO.output(EN_2,GPIO.LOW)
    if (electrode==18 or electrode==20):
      GPIO.output(A0_4,GPIO.HIGH)
    else:
      GPIO.output(A0_4,GPIO.LOW)
    if (electrode==19 or electrode==20):
      GPIO.output(A1_4,GPIO.HIGH)
    else:
      GPIO.output(A1_4,GPIO.LOW)

### Main Loop
while True:
  try:
    time.sleep(0.5)
    print('\n')
    
    starttime = time.time()
    #Swith between electrodes
    for i in range(1,21):
      switch_pin(i)
      time.sleep(0.1)
      average = avgADC()
      if (i==20):
        endtime = time.time()
      print('Electrode '+str(i)+', Voltage: '+ '%.4f' % average)
    meastime = endtime-starttime
    print('Time: '+str(meastime))
    GPIO.output(EN_16,GPIO.LOW)
    GPIO.output(EN_4,GPIO.LOW)
    GPIO.output(EN_2,GPIO.LOW)
  except KeyboardInterrupt:
    GPIO.cleanup()
    sys.exit(0)
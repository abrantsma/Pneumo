import time
import sys
import os
import RPi.GPIO as GPIO
from Adafruit_ADS1x15 import ADS1x15

### Initialize Space
# Input/output
GPIO.setmode(GPIO.BCM)
GPIO.cleanup()
ADS1115 = 0x01
gain = 4096
sps = 250
adc = ADS1x15(ic=ADS1115)


### Choose MUX pins
# First MUX
pin_1a = 27
pin_1b = 17
pin_1c = 4
pin_1in = 22
# Second MUX
pin_2a = 13
pin_2b = 6
pin_2c = 5
pin_2in = 19
# Third MUX
pin_3a = 20
pin_3b = 16
pin_3c = 12
pin_3in = 21
# User Control
pin_b = 25


### Setup MUX
# MUX 1
GPIO.setup(pin_1a,GPIO.OUT)
GPIO.setup(pin_1b,GPIO.OUT)
GPIO.setup(pin_1c,GPIO.OUT)
GPIO.setup(pin_1in,GPIO.OUT)
# MUX 2
GPIO.setup(pin_2a,GPIO.OUT)
GPIO.setup(pin_2b,GPIO.OUT)
GPIO.setup(pin_2c,GPIO.OUT)
GPIO.setup(pin_2in,GPIO.OUT)
# MUX 3
GPIO.setup(pin_3a,GPIO.OUT)
GPIO.setup(pin_3b,GPIO.OUT)
GPIO.setup(pin_3c,GPIO.OUT)
GPIO.setup(pin_3in,GPIO.OUT)
# User Control
GPIO.setup(pin_b,GPIO.IN)


### Initialize MUX
# MUX 1
GPIO.output(pin_1a,GPIO.LOW)
GPIO.output(pin_1b,GPIO.LOW)
GPIO.output(pin_1c,GPIO.LOW)
GPIO.output(pin_1in,GPIO.HIGH)
# MUX 2
GPIO.output(pin_2a,GPIO.LOW)
GPIO.output(pin_2b,GPIO.LOW)
GPIO.output(pin_2c,GPIO.LOW)
GPIO.output(pin_2in,GPIO.HIGH)
# MUX 3
GPIO.output(pin_2a,GPIO.LOW)
GPIO.output(pin_2b,GPIO.LOW)
GPIO.output(pin_2c,GPIO.LOW)
GPIO.output(pin_2in,GPIO.HIGH)


### Functions
# Function for handling logic for switching pins
# Input: electrode we want to turn on (0 index)
def switch_pin(electrode):
    # Initialize by inhibiting everyone
    GPIO.output(pin_1in, GPIO.HIGH)
    GPIO.output(pin_2in, GPIO.HIGH)
    GPIO.output(pin_3in, GPIO.HIGH)
    
    # MUX 1
    if(electrode <= 7):
        e_bin = "{0:b}".format(electrode)
        for i in range(3-len(e_bin)):
            e_bin = '0' + e_bin
        # Switch pin c
        if(e_bin[0] == '0'):
            GPIO.output(pin_1c,GPIO.LOW)
        else:
            GPIO.output(pin_1c,GPIO.HIGH)
        # Switch pin b
        if(e_bin[1] == '0'):
            GPIO.output(pin_1b,GPIO.LOW)
        else:
            GPIO.output(pin_1b,GPIO.HIGH)
        # Switch pin a
        if(e_bin[2] == '0'):
            GPIO.output(pin_1a,GPIO.LOW)
        else:
            GPIO.output(pin_1a,GPIO.HIGH)
        GPIO.output(pin_1in,GPIO.LOW)

    # MUX 2
    elif(electrode <= 15):
        electrode = electrode - 8
        e_bin = "{0:b}".format(electrode)
        for i in range(3-len(e_bin)):
            e_bin = '0' + e_bin
        # Switch pin c
        if(e_bin[0] == '0'):
            GPIO.output(pin_2c,GPIO.LOW)
        else:
            GPIO.output(pin_2c,GPIO.HIGH)
        # Switch pin b
        if(e_bin[1] == '0'):
            GPIO.output(pin_2b,GPIO.LOW)
        else:
            GPIO.output(pin_2b,GPIO.HIGH)
        # Switch pin a
        if(e_bin[2] == '0'):
            GPIO.output(pin_2a,GPIO.LOW)
        else:
            GPIO.output(pin_2a,GPIO.HIGH)
        GPIO.output(pin_2in,GPIO.LOW)

    # MUX 3
    elif(electrode <= 19):
        electrode = electrode - 16
        e_bin = "{0:b}".format(electrode)
        for i in range(3-len(e_bin)):
            e_bin = '0' + e_bin
        # Switch pin c
        if(e_bin[0] == '0'):
            GPIO.output(pin_3c,GPIO.LOW)
        else:
            GPIO.output(pin_3c,GPIO.HIGH)
        # Switch pin b
        if(e_bin[1] == '0'):
            GPIO.output(pin_3b,GPIO.LOW)
        else:
            GPIO.output(pin_3b,GPIO.HIGH)
        # Switch pin a
        if(e_bin[2] == '0'):
            GPIO.output(pin_3a,GPIO.LOW)
        else:
            GPIO.output(pin_3a,GPIO.HIGH)
        GPIO.output(pin_3in,GPIO.LOW)
    else:
        pass


### Main Logic Loop
while True:
    if(GPIO.input(pin_b)==1):
        # Main Output
        s_out = ''
        
        # Wait for hand removal
        time.sleep(0.5)
        n_samp = 100			# Number of samples

        # Switch between electrodes
        for i in range(20):
            switch_pin(i)
            time.sleep(1)         	# Allow for voltage to settle
            meas = 0			
            for j in range(n_samp):	# Grab n samples
                meas += adc.readADCSingleEnded(0, gain, sps)
            meas /= n_samp
            print(str(i+1) + ':' + str(meas))
            s_out = s_out + str(int(meas*10)/10.0) + ' '
        print(s_out)
        GPIO.output(pin_1in,GPIO.HIGH)
        GPIO.output(pin_2in,GPIO.HIGH)
        GPIO.output(pin_3in,GPIO.HIGH)



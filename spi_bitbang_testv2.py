### Bitbang'd SPI interface with an AD7680 ADC device
### AD7680 is a 1-channel 16 bit analog to digital converter
### AD7680 requires 24 bits of data for a complete conversion
### The first and last 4 bits are leading and trailing 0s
### The middle 16 bits are the binary conversion

import RPi.GPIO as GPIO
import time
import sys

# Initialize ADC pins
CLK = 15
MISO = 21
CS = 22

### Functions
# Function to set up the ADC Pins
def setupSpiPins(clkPin, misoPin, csPin):
  # Set all pins as output except MISO (Master Input, Slave Output)
  # There is no MOSI (Master Output, Slave Input)
  GPIO.setup(clkPin,GPIO.OUT)
  GPIO.setup(misoPin,GPIO.IN)
  GPIO.setup(csPin,GPIO.OUT)

# Function to find the average ADC value
def avgADC():
  av = []
  # Define the number of values to average
  numvals = 25
  # Take numvals number of conversions and average them out
  for i in range(numvals):
    val = readAdc(CLK,MISO,CS)
    val = int(val[3:19],2)
    val = val/65536*5
    av.append(val)
  
  average = sum(av)/float(len(av))
  return average

# Function to read ADC through bitbanging
def readAdc(clkPin,misoPin,csPin):
  # cs and clk must be high to begin
  GPIO.output(csPin,GPIO.HIGH)
  GPIO.output(clkPin,GPIO.HIGH)
  
  read_command = 0x18
  adcValue = recvBits(24,csPin,clkPin,misoPin)
  return adcValue

# Function to recieve bits from the ADC
def recvBits(numBits,csPin,clkPin,misoPin):
  # Receives an arbitrary number of bits
  retVal = ''
  # cs must be pulled low to begin conversion
  GPIO.output(csPin,GPIO.LOW)
  
  # Cycle clk low and high for conversion
  # Data clocked out on falling edge
  for bit in range(numBits):
    #Pulse clk pin
    GPIO.output(clkPin,GPIO.LOW)
    GPIO.output(clkPin,GPIO.HIGH)
    
    # Read 1 data bit in
    if GPIO.input(misoPin):
      retVal += '1'
    else:
      retVal += '0'
  
  # Bring cs high to end conversion  
  GPIO.output(csPin,GPIO.HIGH)
  return retVal
  
### Main loop
if __name__ == '__main__':
  try:
    # Setup GPIO pins
    GPIO.setmode(GPIO.BOARD)
    setupSpiPins(CLK,MISO,CS)
    
    # Continuously calculate values
    while True:
      avgADC()
      time.sleep(0.5)
  except KeyboardInterrupt:
    GPIO.cleanup()
    sys.exit(0)
# CraneCorp/PortFlow Embedded Setup

    This file explain how to setup the raspberry pi zero w to work with the project (PortFlow)

## Setup Raspberry Pi Zero W OS

### 1. Downloand The Imager
https://www.raspberrypi.com/software/operating-systems/

1. Chose the Device Raspberry Pi Zero W
2. Chose the Os "Raspberry Pi OS Lite(32-bit)"
3. Chose the sd card as your storage
4. Make the internet connection

![Raspberry Imager](images/rasp_imager.png)
    
### 2. SSH
After downloading the os make the ssh connection from another computer (They need to be in the same WIFI)

```bash
ssh <username>@<IPv4 address> 
```
## 3. Make a directory
```bash
mkdir cranecorp
cd cranecorp
```
## 4. Get the neccesarry libraries
### HTTPLIB
```bash
wget https://raw.githubusercontent.com/yhirose/cpp-httplib/master/httplib.h
```
### PIGPIO
```bash
sudo apt install pigpio
sudo systemctl start pigpiod
sudo systemctl enable pigpiod
```

## 5. Download the source code
```bash
wget https://github.com/ayan-furkan/CRANECORP/blob/main/EMBEDDED/cranecorp.cpp
```

## 6. Compile the Code 
```bash
g++ -o cranecorp cranecorp.cpp -lpigpio -pthread
```
## 7. Run the code 
```bash
sudo ./cranecorp
```
# Apple3SAM
##Apple /// SAM driver

Based on a disassembly of the Apple II SAM programs SAM and RECITER and ported to be a SOS driver for the Apple///. The code had to be modified to allow it to be relocatable, and to work with standard ASCII to suit the Apple/// (Not MSB set ASCII). I'll add the AppleII code to a seperate repository.

The driver outputs to the Apple/// 6 bit DAC. The values are shifted right two bits before outputing. The speech quality seems ok with this approach. I have on the todo list to log the samples from both the A2 and A3 output for the same output and compare.

Two devices are implemented in the driver:  
   .SAM - this can be written to and accepts the standard phonemes as per the A2 SAM.  
   .RECITER - this can be written to and accepts plain text.  
   
The Apple2 SAM implementation allowed the Pitch and Speed parameters to be adjusted by poking values directly into the program. The Apple/// drivers do not allow this so the driver has been coded to be able to set the Pitch and Speed by writing these strings to it:
   ```
   #P<number>
   #S<number>
   Where number is from 0 - 255, eg #P200
   ```
   
   
The error code was able to be read in the original SAM program by peeking the value directly. If an error occurs, eg phoneme not valid, then the error equals the position in the input string where the error occured. If all is ok, the error code = 255. The driver allows the error code to be passed when a read request occurs. The value is returned as ASCII decimal. eg three ascii chars '255' or '002'.
   
##Usage Example

The driver can be used very easily from basic, here is an example program:

   ```
   10 OPEN #1,".RECITER"
   20 PRINT #1;"HELLO"
   30 INPUT #1;ERRCODE$
   ```
See also the disk image for the original SAM provided programs converted to work with the Apple/// Business basic and this driver.

##Compiling
This needs to be assembled with either the Apple/// or AppleII Pascal assembler. The Apple /// SCP will then accept the relocatable .CODE file to be read in as a driver. 
I had some issues getting the correct Pascal text format added to disk image. I ended up using Apple Commander as the way to add the source file to the disk image, and using pascal format disks. I then used Mess running the Apple/// emulation for assembling the code. (the mess command line option -nothrottle speeds the assembly up nicely!)

   ```
   # create pascal disk image
   java -jar ac.jar -pas140 pas.dsk volume1
   #Add source file
   java -jar ac.jar -p pas.dsk samrec.text text < SamReciter.asm
   ```


##Links   
Refer to the original SAM manual for details on the phonemes and other useful info:
[SAM Owner Manual] (http://mirrors.apple2.org.za/Apple%20II%20Documentation%20Project/Interface%20Cards/Speech/Don't%20Ask%20Software%20Automated%20Mouth/Manuals/S.A.M.%20-%20Owner's%20Manual.pdf)

This project was a great help to reverse engineer the disassembly of the SAM code, thanks!
https://github.com/s-macke/SAM

And this was also very useful
http://hitmen.c02.at/html/tools_sam.html

##Todo
The Driver is a little on the large side. I have implemented some extra buffers to simplify the porting process and to get it working. It would be nice to modify the code to remove these, it would trim at least 512bytes of the driver.


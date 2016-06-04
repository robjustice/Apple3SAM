# Apple3SAM
##Apple /// SAM driver

Based on a disassembly of the Apple II SAM programs SAM and RECITER and ported to be a SOS driver for the Apple///. The code had to be modified to allow it to be relocatable, and to work with standard ASCII as the Apple/// does not run with the MSB set for the text. I'll add the AppleII code to a seperate repository.

The driver outputs to the Apple/// 6 bit DAC. The values are shifted right two bits before outputing. The speech quality seems ok with this approach. I have on the todo list to log the samples from both the A2 and A3 output for the same output and compare.

Two devices are implemented in the driver:
   .SAM - this can be written to and accepts the standard phonemes as per the A2 SAM.
   .RECITER - this can be written to and accepts plain text.
   
The Apple2 SAM implementation allowed the Pitch and Speed parameters to be adjusted by poking values directly into the program. The Apple/// drivers do not allow this so the driver has been coded to be able to set the Pitch and Speed by writing these strings to it:
   `#P<number>`
   `#S<number>`
   `Where number is from 0 - 255, eg #P200`
   
The error code was able to be read in the original SAM program by peeking the value directly. If an error occurs, eg phoneme not valid, then the error equals the position in the input string where the error occured. If all is ok, the error code = 255. The driver allowe the error code to be passed when a read request occurs. The value is returned as ASCII decimal. eg three ascii chars '255' or '002'.
   
##Usage Example

The driver can be used very easily from basic, here is an example program:

`10 OPEN #1,".RECITER"`
`20 PRINT #1;"HELLO"`
`30 INPUT #1;ERRCODE$`

   
Refer to the original SAM manual for details on the phonemes and other useful info:
[SAM Owner Manual] (http://mirrors.apple2.org.za/Apple%20II%20Documentation%20Project/Interface%20Cards/Speech/Don't%20Ask%20Software%20Automated%20Mouth/Manuals/S.A.M.%20-%20Owner's%20Manual.pdf)


The Driver is a little on the large side. I have implemented some extra buffers to simplify the porting process and to get it working. It would be nice to modify the code to remove these, it would trim 512bytes of the driver.


//  main.m
//  SuperSimpleMIDIOut
//
//  Created by Iyad Assaf on 22/06/2013.
//
//  Example software that sends control value data out to MIDI devices, this project is configured for use with the Livid Code.
//
//  Output MIDI data can be seen in external MIDI monitors.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

    // Variables & Objects
    MIDIClientRef client;
    MIDIPortRef outputPort;
    BOOL goingUp = TRUE;
    BOOL goingUpNote = TRUE;
    uint note = 1;
    uint velocity = 0;

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        //Endless loop.
        for(;;)
        {            
            //Create the MIDI client and MIDI output port.
            MIDIClientCreate((CFStringRef)@"Midi client", NULL, NULL, &client);
            MIDIOutputPortCreate(client, (CFStringRef)@"Output port", &outputPort);
            
            //Set up the data to be sent
            const UInt8 controlData[] = { 0xB0, note, velocity };
            
            //Create a the packets that will be sent to the device.
            Byte packetBuffer[sizeof(MIDIPacketList)];
            MIDIPacketList *packetList = (MIDIPacketList *)packetBuffer;
            ByteCount size = sizeof(controlData);
            
            MIDIPacketListAdd(packetList,
                              sizeof(packetBuffer),
                              MIDIPacketListInit(packetList),
                              0,
                              size,
                              controlData);
            
            //Enumerate through the avaliable MIDI destinations, send the packets to each one. 
            for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); index++) {
                MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
                    MIDISend(outputPort, outputEndpoint, packetList);
            }
            
            //Dispose of the client and output port devices.
            MIDIClientDispose(client);
            MIDIPortDispose(outputPort);
            
            //Iterate note and velocity
            if (goingUp==TRUE) {
                if (velocity<127) {
                    velocity  = velocity + 1;
                }
                
                if (velocity>=127) {
                    goingUp = FALSE;
                }
            }
            
            if (goingUp==FALSE) {
                velocity  = velocity - 1;
                
                if(velocity==0) {
                    
                    goingUp = TRUE;
                    
                    if (goingUpNote==TRUE) {
                        if (note<32) {
                            note = note + 1;
                        } else {
                            goingUpNote = FALSE;
                        }
                    }
                    
                    if (goingUpNote==FALSE) {
                        note = note - 1;
                        if(note==0)
                        {
                            goingUpNote = TRUE;
                        }
                    }
                    velocity = 0;
                }
            }
            
            //Wait before beginning next cycle.
            [NSThread sleepForTimeInterval:0.001];
            
            NSLog(@"Note - %d, Velocity - %d", note, velocity);
        }
    }
    return 0;
}
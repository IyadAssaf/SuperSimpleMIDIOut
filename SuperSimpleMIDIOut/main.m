//
//  main.m
//  SuperSimpleMIDIOut
//
//  Created by Iyad Assaf on 22/06/2013.
//
//  Example software that sends note and control value data out to MIDI devices, this project is configured for use with the Novation and Livid Code.
//  Output MIDI data can be seen in external MIDI monitors.
//
//  MIDI DATA TYPE VALUES FOR REFERENCE (src = https://ccrma.stanford.edu/~craig/articles/linuxmidi/misc/essenmidi.html)
//
//  0x80     Note Off
//  0x90     Note On
//  0xA0     Aftertouch
//  0xB0     Continuous controller
//  0xC0     Patch change
//  0xD0     Channel Pressure
//  0xE0     Pitch bend
//  0xF0     (non-musical commands)
//
//  //


#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

//Select if you want to output control or note data here. 
#define IS_CONTROL_DATA FALSE

    // Variables & Objects
    MIDIClientRef           client;
    MIDIPortRef             outputPort;
    MIDIEndpointRef         midiOut;
    int                     noteLimit;
    BOOL goingUp =          TRUE;
    BOOL goingUpNote =      TRUE;
    uint note =             0;
    uint velocity =         47;
    int velocityEnumerate = 1;
    int count =             0;


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
            const UInt8 noteOutData[] = {  0x90 , note , velocity};
            
                        
            //Create a the packets that will be sent to the device.
            Byte packetBuffer[sizeof(MIDIPacketList)];
            MIDIPacketList *packetList = (MIDIPacketList *)packetBuffer;
            ByteCount size = sizeof(controlData);
            
            if(IS_CONTROL_DATA==TRUE)
            {
                noteLimit = 32;
                MIDIPacketListAdd(packetList,
                                  sizeof(packetBuffer),
                                  MIDIPacketListInit(packetList),
                                  0,
                                  size,
                                  controlData);
            } else {
                
                noteLimit = 127;
                
                MIDIPacketListAdd(packetList,
                                  sizeof(packetBuffer),
                                  MIDIPacketListInit(packetList),
                                  0,
                                  size,
                                  noteOutData);
            }
            
            //Enumerate through the avaliable MIDI destinations, send the packets to each one. 
            for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); index++) {
                MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
                MIDISend(outputPort, outputEndpoint, packetList);

                //Getting the names of the destinations
                CFStringRef endpointName = NULL;
                MIDIObjectGetStringProperty(outputEndpoint, kMIDIPropertyName, &endpointName);
                char endpointNameC[255];
                CFStringGetCString(endpointName, endpointNameC, 255, kCFStringEncodingUTF8);
//                NSLog(@"The endpoint name at %ld is %s", index, endpointNameC); //Uncomment to log output names.
            }
            
            //Dispose of the client and output port devices.
            MIDIClientDispose(client);
            MIDIPortDispose(outputPort);
            
            if(IS_CONTROL_DATA==TRUE)
            {
            //Iterate note and velocity
            if (goingUp==TRUE) {
                if (velocity<127) {
                    velocity  = velocity + velocityEnumerate;
                }
                
                if (velocity>=127) {
                    goingUp = FALSE;
                }
            }
            
            if (goingUp==FALSE) {
                velocity  = velocity - velocityEnumerate;
                
                if(velocity==0) {
                    goingUp = TRUE;
                    if (goingUpNote==TRUE) {
                        if (note<noteLimit) {
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
            } else {
                count = count +1;
                if(note<127 && goingUp==TRUE)
                {
                    switch (count%4)
                    {
                        case 0:
                            velocity = 47;
                            break;
                        case 1:
                            velocity = 32;
                            break;
                        case 2:
                            velocity = 19;
                            break;
                        case 3:
                            velocity = 0;
                            break;
                    }
                    note = note + 1;

                } else {
                    goingUp = FALSE;
                }
                
                if(note>0 && goingUp==FALSE)
                {
                    if (count%2==0) {
                        velocity = 63;
                    } else {
                        velocity = 10;
                    }
                    note = note -1;
                } else {
                    goingUp = TRUE;
                }
            }
            
            //Wait before beginning next cycle.
            if(IS_CONTROL_DATA==TRUE)
            {
                [NSThread sleepForTimeInterval:0.0001];
                    } else {
                [NSThread sleepForTimeInterval:0.01];
            }
            
            NSLog(@"Note - %d, Velocity - %d", note, velocity);
        }
    }
    return 0;
}


// Read/write 24C0x(or compatible) EEPROMs using a BusPirate
// When reading, data is written to "read.bin"
// When writing, data is is read from "write.bin"
// Currently files are read/written to sketch folder

final int BAUD = 115200;

import controlP5.*;
import processing.serial.*;

Serial serPort;
ControlP5 cp5;

final char STATE_INVALID = 0;
final char STATE_CONFIG  = 1;
final char STATE_READY   = 2;
final char STATE_READING = 3;
final char STATE_WRITING = 4;
final char STATE_ADDRWRITE = 5;
int serstate = STATE_INVALID;
int bytesrecv = 0;
int bytessent = 0;
int respbytes = 0;
byte curblock = 0;
boolean state_pullup = false;
boolean state_pwr = false;

OutputStream outs;
InputStream ins;

void settings() {
    size( 500, 220 );
}

void setup() {
    surface.setTitle("BusPirate EEPROM");
    cp5 = new ControlP5(this);
    initGUI();
}

void draw() {
    background( 0 );
}

void serialEvent( Serial port ) {
    while( port.available() > 0 ) {
        char inbyte = port.readChar();
        if(serstate == STATE_READING) {
            if(respbytes > 0) {
                respbytes--;
                if( inbyte == 1 )
                    print( " OK" );
                else
                    print( " NOK!" );
            }
            else {
                if(bytesrecv%16 == 0)
                    println();
                bytesrecv++;
                String hstr = hex(inbyte).substring(2);
                print( " 0x" );
                print( hstr );

                if(outs != null) { // to file
                    try {
                        outs.write(inbyte);
                    } catch (Exception e) {
                        println( e.getMessage() );
                    }
                }
            }
        }
        else if(serstate == STATE_CONFIG) {
            if(respbytes > 0) {
                respbytes--;
                if( inbyte == 1 )
                    print( " OK" );
                else
                    print( " NOK!" );
            }
            else {
                print( inbyte );
            }
        }
        else if(serstate == STATE_WRITING) {
            if(respbytes > 0) {
                respbytes--;
                if( inbyte == 1 )
                    println( " OK" );
                else
                    println( " NOK!" );
            }
            else {
                //println( " ACK" );
            }
        }
        else if(serstate == STATE_ADDRWRITE) {
            if(respbytes > 0) {
                respbytes--;
                if( inbyte == 1 )
                    print( " OK" );
                else
                    print( " NOK!" );
            }
            else {
                if( inbyte == 0 )
                    print( " ACK" );
                else
                    print( " NACK" );
                if(++bytessent == 2)
                {
                    respbytes = 1;
                }
            }
        }
        else {
            print( inbyte );
        }
    }
}
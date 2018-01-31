
ScrollableList portlist;

void initGUI() {
    
    cp5.addBang("Refresh", 30,30,70,20);
    portlist = cp5.addScrollableList("Ports")
        .setItems( Serial.list() )
        .setPosition(30,70)
        .setSize(70,90)
        .setBarHeight(20)
        .setItemHeight(20);

    cp5.addBang("Connect",    120,30,50,20);
    cp5.addBang("Disconnect", 120,70,50,20);
    
    cp5.addBang("Config", 220,30,50,20);
    cp5.addToggle("Supply",  220,70,50,20);
    cp5.addToggle("Pullups", 220,110,50,20);
    cp5.addBang("RestartHW", 220,150,50,20);
    
    cp5.addBang("Read2k",  320,30,50,20);
    cp5.addBang("Read4k",  320,70,50,20);
    cp5.addBang("Read8k",  320,110,50,20);
    cp5.addBang("Write2k", 420,30,50,20);
    cp5.addBang("Write4k", 420,70,50,20);
    cp5.addBang("Write8k", 420,110,50,20);
}

// GUI Event Handlers

public void Refresh() {
    portlist.setItems( Serial.list() );
}
public void Connect() {
    if( serPort != null )
        Disconnect();
    int selection = (int)(portlist.getValue());
    String port = (String)portlist.getItem(selection).get("name");
    serPort = new Serial(this, port, BAUD);
    delay(1000);
    println( "Connected: "+port );
    
    serstate = STATE_CONFIG;
}
public void Disconnect() {
    if( serPort == null ) return;
    serPort.stop();
    serPort = null;
    println( "Disconnected" );
}

void Config() {
    if( serPort == null ) return;
    serstate = STATE_CONFIG;
    respbytes = 0;
    for(int i=0; i<20; i++) {
        serPort.write(0); // Enter raw bitbang mode
    }
    serPort.write(0x02); // Set binary I2C mode
    delay(50);
    respbytes = 1;
    serPort.write(0x62); // Set speed to 100kHz
}

void configPins() {
    if( serPort == null ) return;
    //if( serstate != STATE_READY ) return;
    serstate = STATE_CONFIG;
    respbytes = 1;
    char cmd = 0x40;
    if(state_pwr)
        cmd |= 0x08;
    if(state_pullup)
        cmd |= 0x04;
    serPort.write( cmd );
}
void Supply(boolean state) {
    state_pwr = state;
    configPins();
}
void Pullups(boolean state) {
    state_pullup = state;
    configPins();
}
void Read2k() { Read_EDID(256); }
void Read4k() { Read_EDID(512); }
void Read8k() { Read_EDID(1024); }
void Write2k() { Write_EDID(256); }
void Write4k() { Write_EDID(512); }
void Write8k() { Write_EDID(1024); }

public void Read_EDID(int size) {
    if( serPort == null ) return;
    
    outs = createOutput("read.bin");
    if(outs == null) {
        println("Failed to create read.bin");
        return;
    }
    
    println("->Reading EEPROM:");
    print("Addr send:");
    serstate = STATE_ADDRWRITE;
    respbytes = 1;
    byte[] abuff = {0x08, 0,2, 0,0, (byte)0xA0, 0};
    serPort.write( abuff );
    println("WR");
    delay(200);
    
    serstate = STATE_READING;
    respbytes = 1;
    bytesrecv = 0;
    println();
    print("Reading:");
    byte[] buff = {0x08, 0,1, (byte)(size>>8),(byte)(size&0xFF), (byte)0xA1};
    println("RD");
    serPort.write( buff );
    delay(1000);
    println();

    try {
    outs.flush();
    outs.close();
    } catch(Exception e) {
        println( e.getMessage() );
    }
    outs = null;
}
public void Write_EDID(int size) {
    if( serPort == null ) return;

    ins = createInput("write.bin");
    if(ins == null) {
        println("Failed to open write.bin");
        return;
    }
    
    serstate = STATE_WRITING;
    println("->Writing:");
    for(int i=0; i<size; i+=8) {
        print("@"+i+": ");
        respbytes = 2;
        bytessent = 0;
        byte[] wrbuf = new byte[5+2+8];
        wrbuf[0] = 0x08; // cmd
        wrbuf[1] = 0; wrbuf[2] = 10; // write amount
        wrbuf[3] = 0; wrbuf[4] = 0; // read amount
        wrbuf[5] = (byte)(0xA0 | ((i>>8)<<1)); // device addr | memory high bits
        wrbuf[6] = (byte)(i&0xFF); // memory addr
        int readcount;
        try {
            readcount = ins.read(wrbuf, 7, 8);
        } catch(Exception e) {
            println( e.getMessage() );
            readcount = 0;
        }
        if(readcount < 8) // eof or error, write 0s
            for(int j=0; j<8; j++)
                wrbuf[7+j] = 0;
        serPort.write( wrbuf );
        delay(50);
    }
    delay(100);
    try {
    ins.close();
    } catch(Exception e) {
        println( e.getMessage() );
    }
    ins = null;
}

void RestartHW() {
    if( serPort == null ) return;
    serstate = STATE_CONFIG;
    respbytes = 1;
    serPort.write(0x0F); // Reset
}
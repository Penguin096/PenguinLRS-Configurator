/**
 * ControlP5 Slider set value
 * changes the value of a slider on keyPressed
 *
 * by Andreas Schlegel, 2012
 * www.sojamo.de/libraries/controlP5
 *
 */

import controlP5.*;
import java.util.*;
import processing.serial.*;

ControlP5 cp5;
Textfield myTextfield;
Serial serial;                   //Define the variable port as a Serial object.
int port;
boolean ConFlag = false;
int myColorBackground = #827560;
char[] RXData = new char[25];
//int[] channels = new int[17];

// #PS
// Выбор портов ---------------------------------------------------

// Номер выбранного порта
int selectedPortNum = 0;

// Флаг Порт выбран
boolean portSelected = false;

// Предыдущее количество портов
// нужно для автоматического обновления списков
int currentCountOfPorts = Serial.list().length;
int prevCountOfPorts = currentCountOfPorts;

// координаты меню селектора
int portListX = 50;
int portListY = 50;
int refreshBtnX = portListX + 250;
int refreshBtnY = portListY;

void setup() {
  size(380, 280);
  background(myColorBackground);
  noStroke();
  cp5 = new ControlP5(this);
  InitSlider();
}

void draw() {

  background(myColorBackground);

  // Если порт выбран 
  if (portSelected) {
    if (serial.available() > 0) {
      if (serial.readChar() == 0x55) {
        for (int i=0; i<25; i++) {
          RXData[i] = serial.readChar();
          if (RXData[i] == 0x0A) break;
        }


        switch (RXData[0]) {
          case  (0xDC):
          cp5.getController("Power").setValue(RXData[1]);
          int a= int((RXData[2]<<8)|RXData[3]);
          if (a <= 125) {
            a = 0;
          } else if (a <= 250) {
            a = 1;
          } else /*if (a <= 500)*/ {
            a = 3;
          }
          cp5.getController("Bandwith").setValue(a);
          cp5.getController("SPREADING FACTOR").setValue(RXData[4]-7);
          cp5.getController("Coding Rate").setValue(RXData[5]-5);
          myTextfield.setText(str((int)RXData[6]));
          cp5.getController("Connected").setValue(1);
          cp5.getController("Read_All").setValue(0);
          ConFlag = true;
          break;
        }
      }
    }
  } else {
    // сравнение числа портов
    currentCountOfPorts = Serial.list().length;
    if (prevCountOfPorts != currentCountOfPorts) {
      // Обновление списка портов
      cp5.get(ScrollableList.class, "Select COM port").clear();
      cp5.get(ScrollableList.class, "Select COM port").setItems(Serial.list());
      prevCountOfPorts = currentCountOfPorts;
    }
  }
}

void controlEvent(ControlEvent theEvent) {
  // Выбор порта
  if (theEvent.getController().getId() == 1) {
    selectedPortNum = (int)theEvent.getController().getValue();
    // остановка ранее подключенного порта
    if (serial != null)
      serial.stop();
    // подключение к выбранному порту
    serial = new Serial(this, Serial.list()[selectedPortNum], 4800, 'E', 8, 1.0);
    portSelected = true;
    cp5.get(ScrollableList.class, "Select COM port").close();
    //Read_All(true);
    byte[] TXData = {(byte)0x55, (byte)0xDD, (byte)0x0A};

    for (int i = 0; i < 3; i++) {
      serial.write(TXData[i]);
    }
    ConFlag = false;
  }
} // Конец controlEvent

void Read_All() {
  if (ConFlag) {
    ConFlag = false;
    //theFlag = Flag;
    byte[] TXData = {(byte)0x55, (byte)0xDD, (byte)0x0A};

    for (int i = 0; i < 3; i++) {
      serial.write(TXData[i]);
    }
    cp5.getController("Read_All").setValue(0);
  }
}

void Wrire_All() {
  if (ConFlag) {
    ConFlag = false;
    byte[] TXData = {(byte)0x55, (byte)0xDB, 0, 0, 0, 0, 0, 0, (byte)0x0A};

    int ia = int(cp5.getController("Power").getValue());
    TXData[2]=(byte)ia;

    ia= int(cp5.getController("Bandwith").getValue());
    if (ia <= 0) {
      ia = 125;
    } else if (ia <= 1) {
      ia = 250;
    } else /*if (a <= 500)*/ {
      ia = 500;
    }
    TXData[3]=(byte)(ia>>8);
    TXData[4]=(byte)ia;

    ia = int(cp5.getController("SPREADING FACTOR").getValue())+7;
    TXData[5]=(byte)ia;
    ia = int(cp5.getController("Coding Rate").getValue())+5;
    TXData[6]=(byte)ia;
    ia = Integer.parseInt(myTextfield.getText());
    TXData[7]=(byte)ia;

    for (int i = 0; i < 9; i++) {
      serial.write(TXData[i]);
    }

    cp5.getController("Wrire_All").setValue(0);
    ConFlag = true;
  }
}

void InitSlider() {

  myTextfield = cp5.addTextfield("Sync Word 0-255")
    .setPosition(20, 170)
    .setSize(100, 40)
    .setFont(createFont("arial", 20))
    .setAutoClear(false)
    //.setInputFilter(1)
    //.setMax(3)
    ;

  List h = Arrays.asList("4/5", "4/6", "4/7", "4/8");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  cp5.addScrollableList("Coding Rate")
    .setPosition(20, 120)
    .setSize(100, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(h)
    .close()
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    ;

  List k = Arrays.asList("SF7", "SF8", "SF9", "SF10", "SF11", "SF12");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  cp5.addScrollableList("SPREADING FACTOR")
    .setPosition(20, 90)
    .setSize(100, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(k)
    .close()
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    ;

  List l = Arrays.asList("125 kHz", "250 kHz", "500 kHz");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  cp5.addScrollableList("Bandwith")
    .setPosition(20, 60)
    .setSize(100, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(l)
    .close()
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    ;

  List j = Arrays.asList("0 dBm", "1 dBm", "2 dBm", "3 dBm", "4 dBm", "5 dBm", "6 dBm", "7 dBm", "8 dBm", "9 dBm", "10 dBm", "11 dBm", "12 dBm", "13 dBm", "14 dBm", "15 dBm", "16 dBm", "17 dBm", "18 dBm", "19 dBm", "20 dBm");
  /* add a ScrollableList, by default it behaves like a DropdownList */
  cp5.addScrollableList("Power")
    .setPosition(20, 30)
    .setSize(100, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(j)
    .close()
    // .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    ;

  cp5.addToggle("Connected")
    .setPosition(300, 60)
    .setSize(50, 20)
    .lock();
  ;

  cp5.addToggle("Read_All")
    .setPosition(300, 140)
    .setSize(50, 20)
    //.lock();
    ;

  cp5.addToggle("Wrire_All")
    .setPosition(300, 180)
    .setSize(50, 20)
    .setColorBackground(#823030)
    .setColorForeground(#a82222)
    .setColorActive(#bf2222)
    //.setMode(ControlP5.SWITCH)
    ;

  // #ID1
  // Меню с выбором из списка доступных портов
  cp5.addScrollableList("Select COM port")
    .setPosition(280, 20)
    .setSize(85, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(Serial.list())
    .setId(1)
    .setType(ScrollableList.LIST) // currently supported DROPDOWN and LIST
    .close();
  ;
}

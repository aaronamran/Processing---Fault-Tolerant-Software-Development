import ipcapture.*;
import hypermedia.net.*;
import grafica.*;
import java.util.*;


//Herausgezogene wichtige Parameter des Systems
boolean TAUSCHE_ANTRIEB_LINKS_RECHTS = false;
float VORTRIEB = 0.75;
float PROPORTIONALE_VERSTAERKUNG = 0.5;
float ASYMMETRIE = 1.01; // 1.0==voll symmetrisch, >1, LINKS STAERKER, <1 RECHTS STAERKER

//VERSION FÜR TP-Link_59C2

//Zugriff auf Konfiguration:
//  http://tplinkwifi.net
//  ODER
//  http://192.168.0.1
//  ODER
//  http://192.168.1.1
//  PASSWORT FÜR ADMINISTRATION: TP-Link_59C2
//  EINRICHTUNG:
//  als Access Point
//  static IP
//  DHCP server enabled

//  Zugang zum access point:

//  hotspot
//  12345678

//  Fahrzeug Kramann: 192.168.0.102

String NACHRICHT = "";
//String TEMPERATUR = "";
//String IP = "192.168.137.92";
//String IP = "192.168.0.102";
//String IP = "192.168.1.103";
String IP = "192.168.178.70";
int PORT = 6000;

//UDP udp;  // define the UDP object
UDPcomfort udpcomfort;  // define the UDP object
Antrieb antrieb;
IPCapture cam;
Bildverarbeitung bildverarbeitung;
Regler regler;
Kalibrierung kalib;
GPlot plot, plotEnd;
Optimierer opt;

int RAND;
int count = 0;

boolean MAINTENANCE = true;
float wFaktor, hFaktor = 0;
//---- To enable graph viewing without needing to run the calibration, set ->  viewGraph = true ----//
boolean viewGraph = false; //by default false
int roundTime = 300;
//
boolean loading = true; //by default true, unless viewing
boolean dataLoaded = false; // by default must be false!


//Optimierer
int ausreisser = 0;
float [] parameters = new float[2];
float [] points;
float [] params;
int RUNDE = 6;
int CURR_RUNDE = 0;
List<float[]> paramsList = new ArrayList<float[]>();
int[] outliers;
boolean isLogged = false;

String initialResData = "initial_points.txt";
String saveFileName = "final_points.txt";

void setup()
{
  size(1280, 900); // Window for maintenance size
  //size(640, 480); // Window for normal

  //read data from file
  String [] data =  loadStrings("parameters.txt");
  int aSize = data.length;
  float[] p = new float[2];
  for (int i = 0; i < aSize; i++) {
    p[i] = Float.valueOf(data[i]);
  }
  //VORTRIEB = p[0];
  //PROPORTIONALE_VERSTAERKUNG = p[1];

  if (MAINTENANCE) {
    // init calibration things including plotter
    plot = new GPlot(this);
    plotEnd = new GPlot(this);
    kalib = new Kalibrierung(plot, plotEnd);

    wFaktor = 4.0;
    hFaktor = 2.0;
  } else {

    wFaktor = 2.0;
    hFaktor = 2.0;
  }

  cam = new IPCapture(this, "http://"+IP+":81/stream", "", "");
  cam.start();
  bildverarbeitung = new Bildverarbeitung(cam);
  udpcomfort = new UDPcomfort(IP, PORT);
  antrieb = new Antrieb(udpcomfort);
  regler = new Regler(antrieb);
  opt = new Optimierer(kalib, new float[]{VORTRIEB, PROPORTIONALE_VERSTAERKUNG});
  RAND = 10; //percent
  paramsList.add(new float[]{VORTRIEB, PROPORTIONALE_VERSTAERKUNG});
  frameRate(10);
}


boolean AKTIV = false;

void draw()
{
  
  
  int[][] BILD = bildverarbeitung.holeRotbild();
  float dx = (width/wFaktor)/(float)BILD[0].length;
  float dy = ((height-420)/hFaktor)/(float)BILD.length;
  image(cam, 0, 0);
  noStroke();

  //1. rect
  fill(200);
  rect(width/(int)wFaktor, 0, width/(int)wFaktor, (height-260)/2); //<>//

  //2. rect
  fill(0);
  for (int i=0; i<BILD.length; i++)
  {
    for (int k=0; k<BILD[i].length; k++)
    {
      if (BILD[i][k]==0)
      {
        rect(width/(int)wFaktor+(float)k*dx, 0+(float)i*dy, dx, dy);
      }
    }
  }

  boolean erfolg = regler.erzeugeStellsignalAusRotbild(BILD);

  // SPX line is drawn here!
  if (erfolg)
  {
    float spx = regler.holeSchwerpunkt();
    stroke(255, 0, 0);
    strokeWeight(3.0);
    line(width/(int)wFaktor+(float)spx, 0, width/(int)wFaktor+(float)spx, (height-420)/2);

    //Kalibrierung.merkenSPX
    //Record only every 1s
    if (AKTIV == true && count%10 == 0 && count <= roundTime) {
      kalib.merkenSPX(spx);
    }
  }

  // save data as file after 500 counts == 50s after Key 1 is pressed
  if (count == roundTime) {

    if (CURR_RUNDE == 0) {
      kalib.saveData(initialResData);
    }

    CURR_RUNDE++;
    if (CURR_RUNDE < RUNDE) {

      //AFTER FIRST RUN GET NEW PARAMS
      points = kalib.removeZeros();
      kalib.resetSPXArray();
      kalib.computeOutliers(points);

      if (CURR_RUNDE != 0)
        opt.step(); // do comparison first then generate new params

      // generate new params
      params = opt.generateNewParameter();
      VORTRIEB = params[0];
      PROPORTIONALE_VERSTAERKUNG = params[1];
      paramsList.add(new float[]{VORTRIEB, PROPORTIONALE_VERSTAERKUNG});
      count = 0; //reset count
      // run again second time
    } else {
      // ONLY IF FINAL ROUND
      //Just to update the last Outlier!
      points = kalib.removeZeros();
      kalib.computeOutliers(points);

      // Save Outlier
      kalib.saveData(saveFileName);
      loading = false;
      // Fahren stoppen
      antrieb.fahrt(0.0, 0.0);
      NACHRICHT = "Fahrt gestoppt";
      AKTIV=false;

      // Printing stuffs
      outliers = kalib.getListOutlier();

      if (!isLogged) {
        String[] o = new String[RUNDE+1];
        o[0] = "RUNDE | VORTRIEB | PORP. VERSTAERKUNG | ANZAHL VON AUSREIßER";
        for (int i = 0; i < RUNDE; i++) {
          o[i+1] = i + " | "+ paramsList.get(i)[0]+  " | "+ paramsList.get(i)[1] +  " | "+ outliers[i];
          println("Runde: " + i+1 + ", Param 1: "+ paramsList.get(i)[0]+ ", Param 2: "+ paramsList.get(i)[1] + ", Outlier Num: "+ outliers[i]);
        }
        saveStrings("log.txt", o);

        //save parameters
        String[] strArr = new String[2];
        // Save last known params into text
        strArr[0] = paramsList.get(paramsList.size()-1)[0] + "";
        strArr[1] = paramsList.get(paramsList.size()-1)[1] + "";
        saveStrings("parameters.txt", strArr);
        isLogged = true;
      }
    }
  }

  stroke(255);
  strokeWeight(0);

  //Lower left rect
  fill(255);
  
  if (MAINTENANCE)
    //rect(0, height/(int)hFaktor - 80, width/(int)wFaktor, height/(int)hFaktor + 80);
    rect(0, height/2 - 210, width/2, height/2 + 210);
  else
    rect(0, height/(int)hFaktor, width/(int)wFaktor, height/(int)hFaktor);
  fill(0);
  textSize(30);
  text(NACHRICHT, 20, height-height/3);
  text(udpcomfort.getTemperatur(), 20, height-height/6);

  fill(255, 0, 0);
  text((int)regler.getProzent()+"%"+" e="+regler.getRegeldifferenz(), 20, height/2 - 220);
 
  if (MAINTENANCE) {
    if (loading == false || viewGraph == true) {
      //if not loading then load data once and plot the data
      
      if (dataLoaded == false) {
        kalib.loadData(initialResData, true);
        kalib.loadData(saveFileName, false);
        dataLoaded = true;
      }
      kalib.draw();
  
    } else if (AKTIV == false & loading == true & viewGraph == false) {
      //give some instruction to the user so that they can begin
      fill(255);
      rect(width/2, 0, width/2, height);
      fill(0);
      textSize(20);
      text("Um die Kalibrierung zu starten, drücken Sie bitte die Taste 1.", width-width/2 + 20, height/2 - 40);
      text("Warten Sie, bis der Zähler " + roundTime + " Counts erreicht", width-width/2 + 20, height/2 - 20);
      text("und der Plot gezeichnet wird.", width-width/2 + 20, height/2);
       
    } else {
      // loading screen
      fill(255);
      rect(width/2, 0, width/2, height);
      fill(0);
      textSize(30);
      text("Aktuelle Parameter = " + VORTRIEB+" ,"+PROPORTIONALE_VERSTAERKUNG, width-width/2 + 20, height/2 - 90);
      text("Aktuelle Runde = " + int(CURR_RUNDE+1), width-width/2 + 20, height/2 - 60);
      text("Die Daten werden erfasst...", width-width/2 + 20, height/2 - 30);
      text("count = " + int(count), width-width/2 + 20, height/2);
    }
  }

  if (AKTIV == true) {
    count++;
  }
}

void keyPressed()
{
  if (key == ' ')
  {
    if (cam.isAlive())
    {
      cam.stop();
      NACHRICHT = "Kamera gestoppt";
    } else
    {
      cam.start();
      NACHRICHT = "Kamera gestartet";
    }
  } else if (key=='0') //stopp
  {
    antrieb.fahrt(0.0, 0.0);
    NACHRICHT = "Fahrt gestoppt";
    AKTIV=false;
  } else if (key=='1') //beide vor
  {
    antrieb.fahrt(1.0, 1.0);
    NACHRICHT = "Fahrt VORWÄRTS";
    AKTIV=true;
  } else if (key=='2') //beide rueck
  {
    antrieb.fahrt(-1.0, -1.0);
    NACHRICHT = "Fahrt RÜCKWÄRTS";
  } else if (key=='3') //links langsam vor
  {
    antrieb.fahrt(0.85, 0.0);
    NACHRICHT = "Fahrt LINKS langsam vor";
  } else if (key=='4') //rechts langsam vor
  {
    antrieb.fahrt(0.0, 0.85);
    NACHRICHT = "Fahrt RECHTS langsam vor";
  } else if (key=='5') //links langsam rück
  {
    antrieb.fahrt(-0.93, 0.0);
    NACHRICHT = "Fahrt LINKS langsam zurück";
  } else if (key=='6') //rechts langsam rück
  {
    antrieb.fahrt(0.0, -0.93);
    NACHRICHT = "Fahrt RECHTS langsam zurück";
  } else if (key=='7') //Kameralicht AN
  {
    udpcomfort.send(4, 1);
    NACHRICHT = "Kameralicht AN";
  } else if (key=='8') //Kameralicht AUS
  {
    udpcomfort.send(4, 0);
    NACHRICHT = "Kameralicht AUS";
  }
}

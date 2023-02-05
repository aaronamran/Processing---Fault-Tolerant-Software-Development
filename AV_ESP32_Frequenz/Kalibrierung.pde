import java.util.*;
import grafica.*;
import java.util.List;


public class Kalibrierung {

  GPlot initialplot, endeplot;
  GPointsArray points;
  GPoint linepoints;
  float[] spxPoints;
  int arrSize; 
  int fixedArraySize = 1000;
  int count = 0;
  int lineColor;
  int smaUp = 0;
  int smaLow = 0;
  int smaLevel = 0;
  int w;
  float [] m;
  int count1 = 0;
  int count2;
  int t = 0;
  float [] shiftedData;

  //save all outliers numbers
  int [] outliers = new int[RUNDE];


  public Kalibrierung(GPlot plot, GPlot plotEnd) {
    this.spxPoints = new float[1000];
    this.initialplot = plot;
    this.endeplot = plotEnd;


    // set position for graph section. does not need to be in setup (works here)
    initialplot.setPos(640, 0);  // 640 0

    // set Margin (bottom, left, top, right)
    initialplot.setMar(60, 60, 50, 40);

    // set plot dimensions (surprisingly trial and error is needed to get these values
    // since it doesnt follow the normal height and width
    initialplot.setDim(550, 340);

    // Set the number of ticks on both axis
    float xAxisRangeAlt = arrSize;
    // idea is to find largest value in array list and use it as max y-axis value to make it dynamic too
    float yAxisRangeAlt = 0;
    initialplot.setXLim(0.0, xAxisRangeAlt);
    initialplot.setYLim(0.0, yAxisRangeAlt);

    // Set axis tick separations
    initialplot.setHorizontalAxesTicksSeparation(5.0);
    initialplot.setVerticalAxesTicksSeparation(10.0);


    // Set the plot title and the axis labels
    initialplot.setTitleText("Initiales Diagramm von Überschreiten der Schwerpunkte");
    initialplot.getXAxis().setAxisLabelText("n");
    initialplot.getYAxis().setAxisLabelText("Schwerpunkt Werte");
    initialplot.setLineColor(30);

    // set position for graph section. does not need to be in setup (works here)
    endeplot.setPos(640, 450);

    // set Margin (bottom, left, top, right)
    endeplot.setMar(320, 60, 50, 40);

    // set plot dimensions (surprisingly trial and error is needed to get these values
    // since it doesnt follow the normal height and width
    endeplot.setDim(550, 320);


    // Set the number of ticks on both axis
    float xAxisRange = arrSize;
    // idea is to find largest value in array list and use it as max y-axis value to make it dynamic too
    float yAxisRange = 0;

    endeplot.setXLim(0.0, xAxisRange);
    endeplot.setYLim(0.0, yAxisRange);

    // Set axis tick separations
    endeplot.setHorizontalAxesTicksSeparation(5.0);
    endeplot.setVerticalAxesTicksSeparation(10.0);


    // Set the plot title and the axis labels
    endeplot.setTitleText("Diagramm von Überschreiten der Schwerpunkte nach Gradientenverfahren");
    endeplot.getXAxis().setAxisLabelText("n");
    endeplot.getYAxis().setAxisLabelText("Schwerpunkt Werte");
    endeplot.setLineColor(30);
  }


  public void merkenSPX(float spx) {
    if (count != this.fixedArraySize) {
      spxPoints[count] = spx;
      count++;
    }
  }

  //save data in txt file
  // data format : point
  public void saveData(String dataName) {
    float[] tmp = removeZeros();
    //println(tmp.length);
    int cnt = tmp.length;
    String[] strArr = new String[cnt];
    // convert float to string
    for (int i = 0; i < tmp.length; i++) {
      strArr[i] = tmp[i] + "";
    }

    // specify directory on Windows!
    saveStrings(dataName, strArr);
  }

  // load Data
  public void loadData(String dataName, boolean graph) {
    // specify directory on Windows!
    String [] data =  loadStrings(dataName);
    arrSize = data.length;
    float [] convData = new float[arrSize];
    shiftedData = new float[arrSize];
    points = new GPointsArray(arrSize);
    for (int i = 0; i < arrSize; i++) {
      convData[i] = Float.valueOf(data[i]);
    }

    computeOutliers(convData);

    for (int i = 0; i < arrSize; i++) {
      //println(shiftedData[i]);
      points.add(i, shiftedData[i]);
    }

    if (graph)
      initialplot.setPoints(points);
    else
      endeplot.setPoints(points);
  }

  public float[] removeZeros() {
    //filter out all 0-Value that exists
    //count non zeros
    int cnt = 0;
    for (int j=0; j < fixedArraySize; j++) {
      if (spxPoints[j] != 0) {
        cnt++;
      }
    }

    // save non-zeros in another array
    float[] temp = new float[cnt];
    cnt = 0;
    for (int j=0; j < fixedArraySize; j++) {
      if (spxPoints[j] != 0) {
        temp[cnt] = spxPoints[j];
        cnt++;
      }
    }

    return temp;
  }

  public void resetSPXArray() {
    //reset spxpoints
    spxPoints = new float[1000];
  }

  public void computeOutliers(float [] convData) {
    count1 = 0;
    //  ++++ Compute Simple Moving Average ++++
    //       Compute the +- 10% from SMA level
    this.smaLevel = computeSMA(convData);
    shiftedData = shiftDatatoZero(convData, smaLevel);
    this.smaUp = int(smaLevel * (10.0/100.0));
    this.smaLow = int(-(smaLevel * (10.0/100.0)));

    println(count1 + ", "  + smaLevel +  ", " + smaUp +" ," + smaLow);

    // Outlier Points
    for (int i = 0; i < shiftedData.length; i++) {
      if (shiftedData[i] < float(smaLow) || shiftedData[i] > float(smaUp)) {
        count1++;
      }
    }
    if (t < RUNDE) {
      outliers[t] = count1;
      t++;
    }
  }

  public int[] getListOutlier() {
    return outliers;
  }

  public int getOutlier() {
    return count1;
  }

  private int computeSMA(float[] arr) {
    int n = 10; // number of values to consider for the moving average
    float sum = 0;
    for (int i = arr.length - n; i < arr.length; i++) {
      sum += arr[i];
    }
    return Math.round(sum / n);
  }

  private float[] shiftDatatoZero(float [] data, int smaLevel) {
    float [] temp = new float[data.length];
    for (int i =0; i < data.length; i++) {
      temp[i] = data[i] - smaLevel;
    }

    return temp;
  }

  public void draw() {
    
    //this is where the graph is drawn

    initialplot.beginDraw();
    initialplot.drawBackground();
    initialplot.drawBox();
    initialplot.drawXAxis();
    initialplot.drawYAxis();
    initialplot.drawTitle();
    // Add horizontal lines at tick numbers on y-axis as midline and borders
    initialplot.drawHorizontalLine(float(0), 30, 2.0);
    initialplot.drawHorizontalLine(float(smaLow), 120, 2.0);
    initialplot.drawHorizontalLine(float(smaUp), 30, 2.0);
    initialplot.drawLines();
    initialplot.drawPoints();
    initialplot.endDraw();

    endeplot.beginDraw();
    endeplot.drawBackground();
    endeplot.drawBox();
    endeplot.drawXAxis();
    endeplot.drawYAxis();
    endeplot.drawTitle();
    // Add horizontal lines at tick numbers on y-axis as midline and borders
    endeplot.drawHorizontalLine(float(0), 30, 2.0);
    endeplot.drawHorizontalLine(float(smaLow), 120, 2.0);
    endeplot.drawHorizontalLine(float(smaUp), 30, 2.0);
    endeplot.drawLines();
    endeplot.drawPoints();
    endeplot.endDraw();
      
     
    textSize(25);
    fill(0);
    text("Anzahl der gemessene Punkte: " + arrSize, width - 1265, height/2-80);
    text("Anzahl der überschreitende Punkte nach der Optimierung: " + count1, width - 1265, height/2-40);
  }
}

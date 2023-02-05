public class Optimierer {

  ArrayList<float[]> data = new ArrayList<float[]>();
  Random zufall = new Random(System.currentTimeMillis());
  Kalibrierung kalib;

  float[] startparameter;
  float[] parameter;
  float[] parameterbest;
  float aktuellerFehler;
  float[] schrittweite;
  int STEP=0;
  int index = 0;
  float alterWert, neuerWert = 0.0;

  public Optimierer(Kalibrierung kalib, float[] startparameter)
  {
    this.kalib = kalib;
    this.startparameter = startparameter;
    aktuellerFehler = 50; // just init
    schrittweite = new float[startparameter.length];
    parameter = new float[startparameter.length];
    parameterbest = new float[startparameter.length];
    for (int i=0; i<schrittweite.length; i++)
      schrittweite[i] = 0.1*Math.abs(startparameter[i]);  //dürfen nicht Null sein!!!
    for (int i=0; i<parameter.length; i++)
      parameter[i] = startparameter[i];
    for (int i=0; i<parameter.length; i++)
      parameterbest[i] = startparameter[i];
  }

  //################################################################
  //################ Gradient Verfahren ############################
  //################################################################

  // splitted into 2 parts because the params has to be run first then it can be improved

  public float[] generateNewParameter() {
    //get current error/outlier before generating new params
    aktuellerFehler = kalib.getOutlier();
    //Wählen, welcher Parameter geändert werden soll:
    index = zufall.nextInt(startparameter.length);

    //Änderung vornehmen, aber alten Wert merken:
    alterWert = parameter[index];
    neuerWert = alterWert + schrittweite[index]*(zufall.nextFloat() - 0.5);

    parameter[index] = neuerWert;

    return parameter;
  }

  public void step() {
    
    float neuerFehler = (float)kalib.getOutlier();

    if (neuerFehler <= aktuellerFehler)
    {
      if (neuerFehler < aktuellerFehler)
      {
        for (int i=0; i<parameter.length; i++)
          parameterbest[i] = parameter[i];

        println("STEP "+STEP+": err="+neuerFehler+" param=");
        for (int i=0; i<parameter.length; i++)
          print(parameter[i]+",");
        println();
      }
      aktuellerFehler = neuerFehler;

      schrittweite[index]*=1.01;
    } else
    {
      parameter[index] = alterWert;
      schrittweite[index]*=0.999;
    }


    STEP++;
  }

}

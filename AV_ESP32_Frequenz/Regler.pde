public class Regler
{
    private float spx = 0.0;
    private Antrieb antrieb;
    private float prozent = 0.0;  
    private float regeldifferenz = 0.0;
    public Regler(Antrieb antrieb)
    {
        this.antrieb = antrieb;
    }
    
    public boolean erzeugeStellsignalAusRotbild(int[][] BILD)
    {
      //Schwerpunkt berechnen und einzeichnen
      //und Prozent an roten Pixeln ermitteln
      float gewicht = 0.0;
      int aktiv=0;
      for(int i=0;i<BILD.length;i++)
      {
         for(int k=0;k<BILD[i].length;k++)
         {
               float wert = (float)BILD[i][k];
               spx += wert*(float)k;
               gewicht+=wert;
               if(wert>0.0) aktiv++;
               
         }
      }
      if(gewicht>0.0)
         spx/=gewicht;
      prozent = 100.0*(float)aktiv/(float)(BILD.length*BILD[0].length);   
      regeldifferenz = 0.0;
      if(prozent>1.0 && prozent<50.0)
      {         
         // +/- 1 0=>nicht genug rote Pixel
         // e<0 => links stärker vor
         // e>0 => rechts stärker vor
         regeldifferenz = ((float)(BILD[0].length/2) - spx)/(float)(BILD[0].length/2);
         if(AKTIV)
         {
              float u_links = 0.0;
              float u_rechts = 0.0;
              
              if(regeldifferenz<0.0)
              {
                  u_links  = VORTRIEB;
                  u_rechts = VORTRIEB + PROPORTIONALE_VERSTAERKUNG*(-regeldifferenz);
              }
              else if(regeldifferenz>0.0)
              {
                  u_links  = VORTRIEB  + PROPORTIONALE_VERSTAERKUNG*(regeldifferenz);
                  u_rechts = VORTRIEB;
              }
              
              u_links*=ASYMMETRIE;
              u_rechts*=(2.0 - ASYMMETRIE);
              
              antrieb.fahrt(u_links,u_rechts);
         }
         return true; //Erfolg
      }
      else
      {
         antrieb.fahrt(0.0,0.0);
         return false; //kein Erfolg
      }
      
    }
    
    public float holeSchwerpunkt()
    {
         return spx;
    }
    
    public float getProzent()
    {
         return prozent;
    }
    public float getRegeldifferenz()
    {
         return regeldifferenz;
    }
}

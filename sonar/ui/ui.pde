// Visualization for sonar program.
// Reads serial port for sonar echo distance and angle and then draws sonar based on those
// Auhor: Pekka Mäkinen

import processing.serial.*;
import java.util.Iterator;

public class Echo
{
    private final float x;
    private final float y;
    private float lifetime;

    public Echo(float _x, float _y)
    {
        x = _x;
        y = _y;
        lifetime = 100;
    }

    public float x() { return x; }
    public float y() { return y; }
    public float lifetime() { return lifetime; }
    public void update(){
      lifetime--;
      if(lifetime>0) {
        noStroke();
        fill(0,230,50, 255*(lifetime/100));
        circle(sonar_x-x,sonar_y-y, 21-20*(lifetime/100));
    }
  }
}

Serial serial;
String val; 


int sonar_x;
int sonar_y;
int max_d;

void setup()
{
  serial = new Serial(this, "COM3", 9600);
  size(1024,600);
  sonar_x = width / 2;
  sonar_y = height - 20;
  max_d = height - 40;
  background(0);
}

ArrayList<Echo> echos = new ArrayList<Echo>();

void draw_borders()
{
  float angle = radians(40);
  float x = (max_d+20)*cos(angle);
  float y = (max_d+20)*sin(angle);
  stroke(200,200,200);
  strokeWeight(2);
  line(sonar_x-x, sonar_y-y, sonar_x, sonar_y);
  
  fill(200,200,200);
  text("25cm", sonar_x - (max_d+20)/4*cos(angle) - 30, sonar_y - (max_d+20)/4*sin(angle) + 40);
  text("50cm", sonar_x - (max_d+20)/2*cos(angle) - 30, sonar_y - (max_d+20)/2*sin(angle) + 40);
  text("75cm", sonar_x - (max_d+20)*3/4*cos(angle)- 30, sonar_y - (max_d+20)*3/4*sin(angle) + 40);
  text("100cm", sonar_x - (max_d+20)*cos(angle) - 30, sonar_y - (max_d+20)*sin(angle)+ 40);

  angle = radians(140);
  x = (max_d+20)*cos(angle);
  y = (max_d+20)*sin(angle);
  line(sonar_x-x, sonar_y-y, sonar_x, sonar_y);
  noFill();
  ellipseMode(RADIUS);
  float angle_start = radians(220);
  float angle_stop = radians(320);
  arc(sonar_x, sonar_y+20, max_d+20, max_d+20, angle_start, angle_stop);
  arc(sonar_x, sonar_y+20, (max_d+20)*3/4, (max_d+20)*3/4, angle_start, angle_stop);
  arc(sonar_x, sonar_y+20, (max_d+20)/2, (max_d+20)/2, angle_start, angle_stop);
  arc(sonar_x, sonar_y+20, (max_d+20)/4, (max_d+20)/4, angle_start, angle_stop);
  stroke(0,230,50, 50);
}

void draw()
{
  float x;
  float y;
  //if ( serial.available() > 0) {
  String val = serial.readStringUntil('\n');
  if(val != null) {
    String[] values = val.split(";");
    if(values.length > 1)
      {
      float angle = parseFloat(values[0])+40;
      float d = parseFloat(values[1]) * max_d;

      if(d!=0) {
        x = d*cos(radians(angle));
        y = d*sin(radians(angle));
        echos.add(new Echo(x,y));
      }
      background(0);
      
      Iterator<Echo> itr = echos.iterator();
      
      while(itr.hasNext()) {
        Echo echo = itr.next();
        echo.update();
        if(echo.lifetime() <= 0) {
          itr.remove();
        }
      }
      //println(echos.size());
      draw_borders();
      strokeWeight(8);
      x = max_d*cos(radians(angle));
      y = max_d*sin(radians(angle));
      line(sonar_x-x,sonar_y-y, sonar_x, sonar_y);
    }
  }
}

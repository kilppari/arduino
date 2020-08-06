// Visualization for sonar program.
// Reads serial port for sonar echo distance and angle and then draws sonar based on those
// Auhor: Pekka Mäkinen

import processing.serial.*;
import java.util.Iterator;

// Define max sonar distance and type. These are used for text label values
float SONAR_DISTANCE = 50;
String SONAR_DISTANCE_TYPE = "cm";

public class Coord
{
  public float x;
  public float y;
  
  public Coord(float _x, float _y)  { x = _x; y = _y; }
  public void setPos(float _x, float _y) { x = _x; y = _y; }
}

public abstract class Drawable
{
  public PMatrix matrix;
  public Drawable() {}
  
  public abstract void draw();
}

public class Line extends Drawable
{
  private final Coord start; 
  private final Coord end; 
  public Line(float x0, float y0, float x1, float y1) {
     start = new Coord(x0, y0);
     end = new Coord(x1, y1);
  }
  public void setPos(float x0, float y0, float x1, float y1){ start.setPos(x0, y0); end.setPos(x1, y1); }
  public void draw() { 
    pushMatrix();
    setMatrix(matrix);
    line(start.x, start.y, end.x, end.y); 
    popMatrix();
  }
}

public class Label extends Drawable
{
  private String text;
  private Coord pos;
  public Label(String _text) {
    text = _text;
    pos = new Coord(0,0);
  }
  
  public void setPos(float _x, float _y) {pos.setPos(_x, _y);}
  public void draw() { text(text, pos.x, pos.y); }
}

public class Arc extends Drawable
{
  private Coord pos;
  private float arcWidth;
  private float arcHeight;
  private float angleStart;
  private float angleEnd;
  public Arc() { pos = new Coord(0, 0);}
  public void draw() { 
    noFill();
    ellipseMode(RADIUS);  
    arc(pos.x, pos.y, arcWidth, arcHeight, angleStart, angleEnd);
  }
  public void setPos(float x, float y, float c, float d, float start, float end) { 
    pos.setPos(x, y); arcWidth = c; arcHeight = d; angleStart = start; angleEnd = end; }
}

public class Background extends Drawable
{
  private int radarAngle;
  private float maxPingLength;
  private Coord pingStartPos;
  private int screenWidth;
  private int screenHeight;
  
  private Line[] lines;
  private Label[] labels;
  private Arc[] arcs;
  
  public Background(int radar_angle) {
    radarAngle = radar_angle;
    
    labels = new Label[4];

    labels[0] = new Label(SONAR_DISTANCE + " " + SONAR_DISTANCE_TYPE);
    labels[1] = new Label(SONAR_DISTANCE*3/4 + " " + SONAR_DISTANCE_TYPE);
    labels[2] = new Label(SONAR_DISTANCE/2 + " " + SONAR_DISTANCE_TYPE);
    labels[3] = new Label(SONAR_DISTANCE/4 + " " + SONAR_DISTANCE_TYPE);
    
    lines = new Line[5];
    for(int i=0; i<lines.length; i++) {
      lines[i] = new Line(0, 0, 0, 0);
    }
    
    arcs = new Arc[4];
    for(int i=0; i<arcs.length; i++) {
      arcs[i] = new Arc();
    }
  }
  
  private void rescale() {
    screenWidth = width;
    screenHeight = height;
    maxPingLength = height - 60;
    pingStartPos = new Coord(width / 2, height-20);
    
    float angle = radians((180 - radarAngle) / 2);
    float leftAngle = PI + angle;
    float rightAngle = 2*PI - angle;
    float d = (maxPingLength+20);
    float d_x = d*cos(angle);
    float d_y = d*sin(angle);
    
    pushMatrix();
    translate(pingStartPos.x, pingStartPos.y);
    rotate(leftAngle);
    for(int i=0; i<lines.length; i++) {
      lines[i].setPos(0, 0, d, 0);
      lines[i].matrix = getMatrix();
      rotate(radians(radarAngle)/(lines.length-1));
    }
    popMatrix();
 
    // Labels along the left-most line
    labels[0].setPos(pingStartPos.x - d_x - 30, pingStartPos.y - d_y + 40);
    labels[1].setPos(pingStartPos.x - d_x*3/4 - 30, pingStartPos.y - d_y*3/4 + 40);
    labels[2].setPos(pingStartPos.x - d_x/2 - 30, pingStartPos.y - d_y/2 + 40);
    labels[3].setPos(pingStartPos.x - d_x/4 - 30, pingStartPos.y - d_y/4 + 40);
    
    // Distance lines for the sonar background
    arcs[0].setPos(pingStartPos.x, pingStartPos.y+20, d, d, leftAngle, rightAngle);
    arcs[1].setPos(pingStartPos.x, pingStartPos.y+20, d*3/4, d*3/4, leftAngle, rightAngle);
    arcs[2].setPos(pingStartPos.x, pingStartPos.y+20, d/2, d/2, leftAngle, rightAngle);
    arcs[3].setPos(pingStartPos.x, pingStartPos.y+20, d/4, d/4, leftAngle, rightAngle);
  }
  
  public void draw() {
    if( screenWidth != width || screenHeight != height) {
      rescale();
    }
    stroke(193,250,170, 100);
    strokeWeight(2);

    for(int i = 0; i < lines.length; i++) {
       lines[i].draw();
    }

    fill(200,200,200);
    for(int i = 0; i < labels.length; i++) {
       labels[i].draw();
    }
    noFill();
    ellipseMode(RADIUS);
    for(int i = 0; i < arcs.length; i++) {
       arcs[i].draw();
    }
    stroke(193,250,170,255);
  }
  
}

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
Background bg = new Background(110);
void setup()
{
  serial = new Serial(this, "COM3", 9600);

  size(1024,600);
  surface.setTitle("Sonar visualizer");
  surface.setResizable(true);
  sonar_x = width / 2;
  sonar_y = height - 20;
  max_d = height - 60;
}

ArrayList<Echo> echos = new ArrayList<Echo>();

float serial_angle = (180-110)/2;
float serial_d = max_d;
void draw()
{
  float x;
  float y;

  background(0);
  bg.draw();

  String val = serial.readStringUntil('\n');
  if(val != null) {
    String[] values = val.split(";");
    if(values.length > 1)
      {
      serial_angle = parseFloat(values[0])+40;
      serial_d = parseFloat(values[1]) * max_d;

      if(serial_d!=0) {
        x = serial_d*cos(radians(serial_angle));
        y = serial_d*sin(radians(serial_angle));
        echos.add(new Echo(x,y));
      }
    }
  }
  Iterator<Echo> itr = echos.iterator();
  
  while(itr.hasNext()) {
    Echo echo = itr.next();
    echo.update();
    if(echo.lifetime() <= 0) {
      itr.remove();
    }
  }
  
  noStroke();
  fill(193,250,170,150);
  strokeWeight(2);
  x = max_d*cos(radians(serial_angle));
  y = max_d*sin(radians(serial_angle));
  arc(sonar_x, sonar_y, max_d+20, max_d+20, PI + radians(serial_angle-7.5), PI + radians(serial_angle+7.5));
}

// In this file you can define your own custom patterns
import java.util.List;
import java.lang.Math;
import java.util.Random;
import java.util.Iterator;
import java.util.Collections;

// Here is a fairly basic example pattern that renders a plane that can be moved
// across one of the axes.
@LXCategory("Form")
public static class PlanePattern extends LXPattern {
  
  public enum Axis {
    X, Y, Z
  };
  
  public final EnumParameter<Axis> axis =
    new EnumParameter<Axis>("Axis", Axis.X)
    .setDescription("Which axis the plane is drawn across");
  
  public final CompoundParameter pos = new CompoundParameter("Pos", 0, 1)
    .setDescription("Position of the center of the plane");
  
  public final CompoundParameter wth = new CompoundParameter("Width", .4, 0, 1)
    .setDescription("Thickness of the plane");
  
  public PlanePattern(LX lx) {
    super(lx);
    addParameter("axis", this.axis);
    addParameter("pos", this.pos);
    addParameter("width", this.wth);
  }
  
  public void run(double deltaMs) {
    float pos = this.pos.getValuef();
    float falloff = 100 / this.wth.getValuef();
    float n = 0;
    for (LXPoint p : model.points) {
      switch (this.axis.getEnum()) {
      case X: n = p.xn; break;
      case Y: n = p.yn; break;
      case Z: n = p.zn; break;
      }
      colors[p.index] = LXColor.gray(max(0, 100 - falloff*abs(n - pos))); 
    }
  }
}

public static class SparklePattern extends LXPattern {
  public enum Axis {
    X, Y, Z
  };

  public final CompoundParameter frequency = new CompoundParameter("Frequency", 5000, 0, 10000)
    .setDescription("How often to create a new sparkle");
    
  public final CompoundParameter variance = new CompoundParameter("Variance", 0, 0, 10000)
    .setDescription("How much to vary creation frequency"); 
  
  public final CompoundParameter radius = new CompoundParameter("Radius", 0.01, 0, 1)
    .setDescription("Sparkle radius");
    
  public final CompoundParameter lifetime = new CompoundParameter("Lifetime", 1000, 0, 10000)
    .setDescription("Sparkle lifetime");
    
  public final CompoundParameter lifetimeVariance = new CompoundParameter("LifeVar", 0.5, 0, 1)
    .setDescription("Sparkle lifetime variance");
  
  private final List<SparkleLayer> sparkles = new ArrayList<SparkleLayer>();
  
  private long lastSparkle = 0;
  private Random rand = new Random();
  
  public SparklePattern(LX lx) {
    super(lx);
    addParameter("frequency", this.frequency);
    addParameter("variance", this.variance);
    addParameter("radius", this.radius);
    addParameter("lifetime", this.lifetime);
    addParameter("lifetimevar", this.lifetimeVariance);
  }
  
  void newSparkle() {
    double life = lifetime.getValue() + ((Math.random() - 0.5) * lifetimeVariance.getValue() * lifetime.getValue());
    System.out.println(life);
 
    LXPoint target = lx.model.points[rand.nextInt(lx.model.points.length)];
    
    SparkleLayer sparkle = new SparkleLayer(lx, radius.getValue(), life, new LXVector(target.x,target.y,target.z));
    
    addLayer(sparkle);
    sparkles.add(sparkle);
  }
  
  void removeSparkle(SparkleLayer sparkle) {
    removeLayer(sparkle);
    sparkles.remove(sparkle);
  }
  
  private class SparkleLayer extends LXLayer {    
    private final double radius;
    private final double lifetime;
    private final LXVector position;
    
    private final LXPeriodicModulator sparkleModulator; 
    
    private SparkleLayer(LX lx, double radius, double lifetime, LXVector position) {
      super(lx);
      this.radius = radius;
      this.lifetime = lifetime;
      this.position = position;
      
      sparkleModulator = new SinLFO(0, 1, lifetime);
      sparkleModulator.setLooping(false);
      startModulator(sparkleModulator);
    }
    
    public void run(double deltaMs) {      
      for (LXPoint p : model.points) {        
        double distance = this.position.dist(new LXVector(p));
        
        if (distance < this.radius) {
          double brightness = (radius - distance) / radius;
          if (brightness > 0.95f) {
            brightness = 1;
          }
          
          colors[p.index] = LXColor.gray(brightness * sparkleModulator.getValue() * 100);
        }
      }
    }
    
    public boolean isFinished() {
      return !sparkleModulator.isRunning();
    }
  }
  
  public void run(double deltaMs) {
    lastSparkle += deltaMs;
    if (lastSparkle > frequency.getValue() + (Math.random() - 0.5) * variance.getValue()) {
      // New sparkle time!
      newSparkle();
      lastSparkle = 0;
    }
    
    for (SparkleLayer sparkle : sparkles) {
      if (sparkle.isFinished()) removeLayer(sparkle);
    }
  }
}

public static class NoisePattern extends LXPattern {
  public final CompoundParameter min = new CompoundParameter("Min", 0, 0, 100)
    .setDescription("Noise min");
    
  public final CompoundParameter max = new CompoundParameter("Max", 100, 0, 100)
    .setDescription("Noise max"); 
    
  public final CompoundParameter speed = new CompoundParameter("Speed", 500, 0, 1000)
    .setDescription("Speed (time between frames)");
    
  private final LXPeriodicModulator animationModulator = new LinearEnvelope(0, 1, speed);
  
  private int thisFrame = 0;
  private int nextFrame = 1;
  private final double[][] frames = new double[2][colors.length];
  private final Random rand = new Random();
  
  public NoisePattern(LX lx) {
    super(lx);
    addParameter("min", this.min);
    addParameter("max", this.max);
    addParameter("speed", this.speed);

    fillFrame(thisFrame);
    fillFrame(nextFrame);
    
    animationModulator.setLooping(true);
    startModulator(animationModulator);
  }
  
  void fillFrame(int index) {
    for (int i = 0; i < frames[index].length; i++) {
      frames[index][i] = rand.nextDouble() * (max.getValue() - min.getValue()) + min.getValue();
    }
  }
  
  void showFrame(int thisFrame, int nextFrame, double mix) {
    for (int i = 0; i < colors.length; i++) {
      double start = frames[thisFrame][i];
      double end = frames[nextFrame][i];
      colors[i] = LXColor.gray(start + (end - start) * mix);
    }
  }

  public void run(double deltaMs) {
    if (animationModulator.loop()) {  
      showFrame(nextFrame, nextFrame, 1);
      
      thisFrame = (thisFrame + 1) % 2;
      nextFrame = (nextFrame + 1) % 2;
      
      fillFrame(nextFrame);
    } else {
      showFrame(thisFrame, nextFrame, animationModulator.getValue());
    }
  }
}

public static class RainPattern extends LXPattern {
  private final double DROP_RADIUS = 0.1;
  private final LXVector DIRECTION = new LXVector(0, -1, 0);
  
  public final CompoundParameter birthrate = new CompoundParameter("Birthrate", 1, 0, 5)
    .setDescription("Rate of creation of drops (/ s)");
    
  public final CompoundParameter velocity = new CompoundParameter("Velocity", 0.2, 0, 1)
    .setDescription("Velocity (unit / s)");
    
  public final CompoundParameter tailLength = new CompoundParameter("Length", 5, 0, 50)
    .setDescription("Length of tail");
    
  public final BooleanParameter forward = new BooleanParameter("Forward", true)
    .setDescription("Droplet direction on strip");
    
  public final BooleanParameter sync = new BooleanParameter("Sync", true)
    .setDescription("Sync beam front and back");
    
  private final List<Droplet> droplets = new ArrayList<Droplet>();
  private final Random rand = new Random();
  
  public RainPattern(LX lx) {
    super(lx);
    
    addParameter("birthrate", this.birthrate);
    addParameter("velocity", this.velocity);
    addParameter("tailLength", this.tailLength);
    addParameter("forward", this.forward);
    addParameter("sync", this.sync);
  }
  
  public void addDroplet(List<LXPoint> strip) {
    Droplet drop = new Droplet(lx, strip, tailLength.getValue());
    droplets.add(drop);
    addLayer(drop);
  }
  
  public void run(double deltaMs) {
    if (rand.nextDouble() < birthrate.getValue() * deltaMs / 1000) {
      List<Fixture> beams = ((GridModel3D)lx.model).beams;
      Fixture beam = beams.get(rand.nextInt(beams.size()));
      
      List<List<LXPoint>> strips = new ArrayList<List<LXPoint>>();
      if (sync.isOn()) {
        strips.add(beam.front);
        strips.add(beam.back);
      } else {
        strips.add(rand.nextInt(1) == 1 ? beam.front : beam.back);
      }
      
      for (List<LXPoint> strip : strips) {
        List<LXPoint> stripCopy = new ArrayList<LXPoint>(strip);
        if (!forward.isOn()) Collections.reverse(stripCopy);
        addDroplet(stripCopy);
      }
    }
    
    for (Iterator<Droplet> i = droplets.iterator(); i.hasNext(); ) { 
      Droplet drop = i.next();
      
      if (drop.finished()) {
        removeLayer(drop);
        i.remove();
      }
    }
  }
  
  private class Droplet extends LXLayer {
    private final List<LXPoint> strip;
    private final LXPeriodicModulator position;
    private final int posMax;
    private final double tailLength;
    
    Droplet(LX lx, List<LXPoint> strip, double tailLength) {
      super(lx);
      
      this.strip = strip;      
      this.tailLength = tailLength;
      posMax = strip.size() + (int)Math.ceil(tailLength) + 1;

      position = new LinearEnvelope(0, posMax, 1000 / velocity.getValue());
      startModulator(position);
    }
    
    public void run(double deltaMs) {
      int i = 0;

      for (LXPoint p : strip) {        
        double distance = position.getValue() - i;
        
        if (distance >= 0 && distance <= tailLength) {    
          double brightness = (tailLength - distance) / tailLength;
          colors[p.index] = LXColor.gray(brightness * 100);
        }
        
        i++;
      }
    }
    
    public boolean finished() { 
      return !position.isRunning();
    }
  }
}

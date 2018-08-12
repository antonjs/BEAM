// In this file you can define your own custom patterns
import java.util.List;
import java.lang.Math;

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

  public final CompoundParameter frequency = new CompoundParameter("Frequency", 0, 1)
    .setDescription("How often to create a new sparkle");
  
  public final CompoundParameter radius = new CompoundParameter("Radius", 1*IN, 0, 1*FEET)
    .setDescription("Sparkle radius");
    
  public final CompoundParameter lifetime = new CompoundParameter("Lifetime", 1000, 0, 10000)
    .setDescription("Sparkle lifetime");
  
  private final List<SparkleLayer> sparkles = new ArrayList<SparkleLayer>();
  
  public SparklePattern(LX lx) {
    super(lx);
    addParameter("frequency", this.frequency);
    addParameter("radius", this.radius);
    addParameter("lifetime", this.lifetime);
    
    SparkleLayer sparkle = new SparkleLayer(lx, this, this.radius.getValue(), this.lifetime.getValue(), new LXVector(0,lx.model.cy,lx.model.cz));
    addLayer(sparkle);
  }
  
  private class SparkleLayer extends LXLayer {
    public SparklePattern parent;
    
    private final double radius;
    private final double lifetime;
    private final LXVector position;
    
    private final LXPeriodicModulator sparkleModulator; 
    
    private SparkleLayer(LX lx, SparklePattern parent, double radius, double lifetime, LXVector position) {
      super(lx);
      this.parent = parent;
      this.radius = radius;
      this.lifetime = lifetime;
      this.position = position;
      
      sparkleModulator = new SinLFO(0, 1, 1000);
      //sparkleModulator.setLooping(false);
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
    
    public boolean finished() {
      return sparkleModulator.isRunning();
    }
  }
  
  public void run(double deltaMs) {
    //if (Math.random() < 0.05) {
    //  SparkleLayer sparkle = new SparkleLayer(lx, this, this.radius.getValue(), this.lifetime.getValue(), new LXVector(0,0,0)); 
    //  addLayer(sparkle);
    //  this.sparkles.add(sparkle);
    //}
  }
}

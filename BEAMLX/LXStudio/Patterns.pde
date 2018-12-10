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

  public final CompoundParameter density = new CompoundParameter("Density", 0.2f, 0, 1)
    .setDescription("How dense should we make the sparkles?");
  
  public final CompoundParameter radius = new CompoundParameter("Radius", 0.01f, 0, 1)
    .setDescription("Sparkle radius");
    
  public final CompoundParameter lifetime = new CompoundParameter("Lifetime", 100, 0, 1000)
    .setDescription("Sparkle lifetime");
    
  public final CompoundParameter lifetimeVariance = new CompoundParameter("LifeVar", 0.5f, 0, 1)
    .setDescription("Sparkle lifetime variance");
  
  private final List<SparkleLayer> sparkles = new ArrayList<SparkleLayer>();
  
  private Random rand = new Random();
  
  public SparklePattern(LX lx) {
    super(lx);
    addParameter("density", this.density);
    addParameter("radius", this.radius);
    addParameter("lifetime", this.lifetime);
    addParameter("lifetimevar", this.lifetimeVariance);
  }
  
  public void newSparkle() {
    double life = lifetime.getValue() + ((Math.random() - 0.5f) * lifetimeVariance.getValue() * lifetime.getValue());
 
    LXPoint target = lx.model.points[rand.nextInt(lx.model.points.length)];
    
    SparkleLayer sparkle = new SparkleLayer(lx, radius.getValue(), life, new LXVector(target.x,target.y,target.z));
    
    addLayer(sparkle);
    sparkles.add(sparkle);
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
    double currentDensity = 1.0f * sparkles.size() / colors.length;
    while (currentDensity < density.getValue()) {
      if (rand.nextDouble() < 1 - currentDensity) {
        // New sparkle time!
        newSparkle();
      }
      
      currentDensity = 1.0f * sparkles.size() / colors.length;
    }
    
    for (Iterator<SparkleLayer> i = sparkles.iterator(); i.hasNext(); ) {
      SparkleLayer sparkle = i.next();
      if (sparkle.isFinished()) {
        removeLayer(sparkle);
        i.remove();
      }
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
  
  public void fillFrame(int index) {
    for (int i = 0; i < frames[index].length; i++) {
      frames[index][i] = rand.nextDouble() * (max.getValue() - min.getValue()) + min.getValue();
    }
  }
  
  public void showFrame(int thisFrame, int nextFrame, double mix) {
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
  private final double DROP_RADIUS = 0.1f;
  private final LXVector DIRECTION = new LXVector(0, -1, 0);
  
  public final CompoundParameter birthrate = new CompoundParameter("Birthrate", 1, 0, 10)
    .setDescription("Rate of creation of drops (/ s)");
    
  public final CompoundParameter velocity = new CompoundParameter("Velocity", 0.2f, 0, 1)
    .setDescription("Velocity (unit / s)");
    
  public final CompoundParameter tailLength = new CompoundParameter("Length", 5, 0, 50)
    .setDescription("Length of tail");
    
  public final BooleanParameter forward = new BooleanParameter("Forward", true)
    .setDescription("Droplet direction on strip");
    
  public final BooleanParameter sync = new BooleanParameter("Sync", true)
    .setDescription("Sync beam front and back");
    
  public final BooleanParameter trigger = new BooleanParameter("Trigger", true)
    .setDescription("Trigger new drop");
    
  private final List<Droplet> droplets = new ArrayList<Droplet>();
  private final Random rand = new Random();
  
  public RainPattern(LX lx) {
    super(lx);
    
    addParameter("birthrate", this.birthrate);
    addParameter("velocity", this.velocity);
    addParameter("tailLength", this.tailLength);
    addParameter("forward", this.forward);
    addParameter("sync", this.sync);
    addParameter("trigger", this.trigger);
    
    LXParameterListener listener = new LXParameterListener() {
      public @Override
      void onParameterChanged(LXParameter param) {
        addDroplet();
      }
    };
    
    this.trigger.addListener(listener);
  }
  
  public void addDroplet() {
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
  
  public void addDroplet(List<LXPoint> strip) {
    Droplet drop = new Droplet(lx, strip, tailLength.getValue());
    droplets.add(drop);
    addLayer(drop);
  }
  
  public void run(double deltaMs) {
    if (rand.nextDouble() < birthrate.getValue() * deltaMs / 1000) {
      addDroplet();
    }
    
    for (Iterator<Droplet> i = droplets.iterator(); i.hasNext(); ) { 
      Droplet drop = i.next();
      
      if (drop.finished()) {
        removeLayer(drop);
        i.remove();
      }
    }
    
    for (int i = 0; i < colors.length; i++) {
      colors[i] = LXColor.gray(0);
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
          addColor(p.index, LXColor.gray(brightness * 100));
        } else {
          //colors[p.index] = LXColor.gray(0);
        }
        
        i++;
      }
    }
    
    public boolean finished() { 
      return !position.isRunning();
    }
  }
}

public static class BlockPattern extends LXPattern {
  public final DiscreteParameter fragments = new DiscreteParameter("Fragments", 2, 0, 8)
    .setDescription("Number of fragments");
    
  public final BooleanParameter invert = new BooleanParameter("Invert", false)
    .setDescription("Invert colors");
    
  public final BooleanParameter beamSync = new BooleanParameter("BeamSync", true)
    .setDescription("Sync alignment beam-to-beam");
    
  public final BooleanParameter sideSync = new BooleanParameter("SideSync", true)
    .setDescription("Sync alignment side-to-side");
    
  private final boolean[] seeds = new boolean[((GridModel3D)lx.model).NUM_BEAMS * 2];
  private final Random rand = new Random();
  
  public BlockPattern(LX lx) {
    super(lx);
    addParameter("fragments", this.fragments);
    addParameter("invert", this.invert);
    addParameter("beamSync", this.beamSync);
    addParameter("sideSync", this.sideSync);
    
    LXParameterListener listener = new LXParameterListener() {
      public @Override
      void onParameterChanged(LXParameter param) {
        reseed();
      }
    };
    
    this.beamSync.addListener(listener);
    this.sideSync.addListener(listener);
    
    reseed();
  }
  
  public void reseed() {
    for (int i = 0; i < seeds.length; i ++) {
      if (i % 2 == 0) {
        seeds[i] = beamSync.isOn() ? true : (i / 2 % 2) == 0;
      } else {
        seeds[i] = sideSync.isOn() ? seeds[i - 1] : !seeds[i-1];
      }
    }
  }

  public void run(double deltaMs) {
    List<Fixture> beams = ((GridModel3D)lx.model).beams;
    int beamIndex = 0;
    
    for (Fixture beam : beams) {    
      for (List<LXPoint> strip : beam.sides) {
        int fragSize = (int)(strip.size() / fragments.getValue());
        boolean white = seeds[beamIndex++];
        for (int i = 0; i < strip.size(); i++) {
          colors[strip.get(i).index] = white ^ invert.isOn() ? LXColor.WHITE : LXColor.BLACK;
          if ((i+1) % fragSize == 0) white = !white;
        }
      }
    }
  }
}


public static class BarPattern extends LXPattern {
  public final BooleanParameter trigger = new BooleanParameter("trigger", true)
    .setDescription("trigger next");
  
  public final CompoundParameter speed = new CompoundParameter("Speed", 500, 0, 1000)
    .setDescription("Speed (time between frames)");
    
  private final boolean[] seeds = new boolean[((GridModel3D)lx.model).NUM_BEAMS * 2];
  private final Random rand = new Random();
  
  
  private int barInt = 0;
  
  public BarPattern(LX lx) {
    super(lx);
    addParameter("trigger", this.trigger);
    
    LXParameterListener listener = new LXParameterListener() {
      public @Override
      void onParameterChanged(LXParameter param) {
        step();
      }
    };
    
    this.trigger.addListener(listener);
    
    step();
  }
  
  public void step() {
    barInt++;
    barInt = barInt > ((GridModel3D)lx.model).NUM_BEAMS - 1 ? 0 : barInt;
    System.out.println(barInt);
  }

  public void run(double deltaMs) {
    List<Fixture> beams = ((GridModel3D)lx.model).beams;
    int beamIndex = 0;
    
    for (Fixture beam : beams) {    
      if (beamIndex++ == barInt) {
        for (List<LXPoint> strip : beam.sides) {
          for (int i = 0; i < strip.size(); i++) {
            colors[strip.get(i).index] = LXColor.gray(100);
          }
        }
      }
      else {
        for (List<LXPoint> strip : beam.sides) {
          for (int i = 0; i < strip.size(); i++) {
            colors[strip.get(i).index] = LXColor.gray(0);
          }
        }
      }
    }
  }
}

public static class BarChainPattern extends LXPattern {
  public final BooleanParameter trigger = new BooleanParameter("trigger", true)
    .setDescription("trigger next");
  
  public final BooleanParameter dual = new BooleanParameter("dual", true)
    .setDescription("dual");
  
  public final CompoundParameter speed = new CompoundParameter("Speed", 50, 30, 600)
    .setDescription("Speed (time between frames)");
  
  private final LXPeriodicModulator animationModulator = new LinearEnvelope(0, ((GridModel3D)lx.model).NUM_BEAMS, speed);
  
  private int barInt = 0;
  
  private boolean chain = false;
  private boolean mirror = true;
  
  public BarChainPattern(LX lx) {
    super(lx);
    addParameter("trigger", this.trigger);
    addParameter("dual", this.dual);
    addParameter("speed", this.speed);
    
    LXParameterListener listener = new LXParameterListener() {
      public @Override
      void onParameterChanged(LXParameter param) {
        step();
      }
    };
    
    LXParameterListener duallistener = new LXParameterListener() {
      public @Override
      void onParameterChanged(LXParameter param) {
        mirror = !mirror;
      }
    };
    
    this.trigger.addListener(listener);
    this.dual.addListener(duallistener);
        
    animationModulator.setLooping(true);
    startModulator(animationModulator);
    
    step();
  }
  
  public void step() {
    chain = true;
    barInt = -1;
  }

  public void run(double deltaMs) {
    List<Fixture> beams = ((GridModel3D)lx.model).beams;
    int beamIndex = 0;
    
    if (animationModulator.loop()) {  
      barInt++;
      if (barInt >= ((GridModel3D)lx.model).NUM_BEAMS) {
        chain = false;
        for (Fixture beam : beams) {
          for (List<LXPoint> strip : beam.sides) {
            for (int i = 0; i < strip.size(); i++) {
              colors[strip.get(i).index] = LXColor.gray(0);
            }
          }
        }
      }
    } else {
      if (chain == true) {
        for (Fixture beam : beams) {    
          if (beamIndex++ == barInt) {
            for (List<LXPoint> strip : beam.sides) {
              for (int i = 0; i < strip.size(); i++) {
                colors[strip.get(i).index] = LXColor.gray(100);
              }
            }
          } else if (mirror && beamIndex == ((GridModel3D)lx.model).NUM_BEAMS - barInt) {
              for (List<LXPoint> strip : beam.sides) {
                for (int i = 0; i < strip.size(); i++) {
                  colors[strip.get(i).index] = LXColor.gray(100);
                }
              }
            } else {
            for (List<LXPoint> strip : beam.sides) {
              for (int i = 0; i < strip.size(); i++) {
                colors[strip.get(i).index] = LXColor.gray(0);
              }
            }
          }
        }
      }
    }
  }
}

public static class BarRandPattern extends LXPattern {
  
  public final CompoundParameter speed = new CompoundParameter("Speed", 50, 30, 600)
    .setDescription("Speed (time between frames)");
    
  public final CompoundParameter rate = new CompoundParameter("Rate", 50, 0, 100)
    .setDescription("Rate");
  
  private final LXPeriodicModulator animationModulator = new LinearEnvelope(0, ((GridModel3D)lx.model).NUM_BEAMS, speed);
  
  private final Random rand = new Random();
  
  private int barInt = 0;
  
  private boolean chain = false;
  private boolean mirror = true;
  
  public BarRandPattern(LX lx) {
    super(lx);
    addParameter("speed", this.speed);
    addParameter("rate", this.rate);
        
    animationModulator.setLooping(true);
    startModulator(animationModulator);
    
    step();
  }
  
  public void step() {
    chain = true;
    barInt = -1;
  }

  public void run(double deltaMs) {
    List<Fixture> beams = ((GridModel3D)lx.model).beams;
    
    if (animationModulator.loop()) {  
      for (Fixture beam : beams) {    
        double barShow = 100*rand.nextDouble();
        System.out.println(barShow);
        System.out.println(rate.getValue());
        if (barShow < rate.getValue()) {
          for (List<LXPoint> strip : beam.sides) {
            for (int i = 0; i < strip.size(); i++) {
              colors[strip.get(i).index] = LXColor.gray(100);
            }
          }
        } else {
          for (List<LXPoint> strip : beam.sides) {
            for (int i = 0; i < strip.size(); i++) {
              colors[strip.get(i).index] = LXColor.gray(0);
            }
          }
        }
      }
    }
  }
}

public static class BarMaskPattern extends LXPattern {
  public final List<BooleanParameter> triggers = new ArrayList<BooleanParameter>();
  
  public final CompoundParameter speed = new CompoundParameter("Decay", 500, 0, 1000)
    .setDescription("Fade delay after trigger");
    
  private final boolean[] seeds = new boolean[((GridModel3D)lx.model).NUM_BEAMS * 2];
  private final Random rand = new Random();
  
  
  private int barInt = 0;
  
  public BarMaskPattern(LX lx) {
    super(lx);
    
    LXParameterListener listener = new LXParameterListener() {
      public @Override
      void onParameterChanged(LXParameter param) {
      }
    };
    
    for (int i = 0; i < ((GridModel3D)lx.model).NUM_BEAMS; i++) {
      BooleanParameter trigger = new BooleanParameter(Integer.toString(i), false)
        .setMode(BooleanParameter.Mode.MOMENTARY)
        .setDescription("Trigger bar");
       addParameter("trigger/" + Integer.toString(i), trigger);
       //trigger.addListener(listener);
       triggers.add(trigger);
    }
  }
  
  public void run(double deltaMs) {
    List<Fixture> beams = ((GridModel3D)lx.model).beams;
    int beamIndex = 0;
    
    for (Fixture beam : beams) {
      for (List<LXPoint> strip : beam.sides) {
        for (int i = 0; i < strip.size(); i++) {
          colors[strip.get(i).index] = LXColor.gray(triggers.get(beamIndex).isOn() ? 100 : 0);
        }
      }
      
      beamIndex++;
    }
  }
}

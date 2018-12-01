import java.util.Collections;
import java.util.List;
import java.util.Arrays;

public LXModel buildModel() {
    final List<Fixture> beams = new ArrayList<Fixture>();
    
    for (int i = 0; i < GridModel3D.NUM_BEAMS; i++) {
      beams.add(new Fixture(i * 0.2f, 0));
    }
    
  // A three-dimensional grid model
  return new GridModel3D(beams);
}

public static class GridModel3D extends LXModel { 
  public static final int NUM_BEAMS = 12;
  
  public final List<Fixture> beams;
  
  public GridModel3D(List<Fixture> beams) {
    super(beams.toArray(new Fixture[beams.size()]));
    this.beams = Collections.unmodifiableList(beams);    
  }
}

public static class Fixture extends LXAbstractFixture {
  public final static int SIZE = 100;
  
  public final static float LED_SPACING = 0.016f;
  public final static float SIDE_SPACING = LED_SPACING * 10; // Space between front and back columns

  
  public final float maxY = SIZE * LED_SPACING;
  public final List<LXPoint> front;
  public final List<LXPoint> back;
  public final List<List<LXPoint>> sides;
  
  Fixture(float x, float z) {
    List<LXPoint> front = new ArrayList<LXPoint>();
    List<LXPoint> back = new ArrayList<LXPoint>();
    List<List<LXPoint>> sides = new ArrayList<List<LXPoint>>();

    for (float y = 0; y < SIZE; y += 1) {
      LXPoint p = new LXPoint(x, y * LED_SPACING, z);
      addPoint(p);
      front.add(p);
    }
    
    for (float y = 0; y < SIZE; y += 1) {
      LXPoint p = new LXPoint(x, y * LED_SPACING, z + SIDE_SPACING);
      addPoint(p);
      back.add(p);
    }
    
    this.front = Collections.unmodifiableList(front);
    this.back = Collections.unmodifiableList(back);
    
    sides.add(this.front);
    sides.add(this.back);
    this.sides = Collections.unmodifiableList(sides);
  }
}

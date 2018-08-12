import java.util.Collections;
import java.util.List;
import java.util.Arrays;

LXModel buildModel() {
    final int NUM_BEAMS = 2;
    final List<Fixture> beams = new ArrayList<Fixture>();
    
    for (int i = 0; i < NUM_BEAMS; i++) {
      beams.add(new Fixture(i * 2, 0));
    }
    
  // A three-dimensional grid model
  return new GridModel3D(beams);
}

public static class GridModel3D extends LXModel {  
  public final List<Fixture> beams;
  
  public GridModel3D(List<Fixture> beams) {
    super(beams.toArray(new Fixture[beams.size()]));
    this.beams = Collections.unmodifiableList(beams);    
  }
}

public static class Fixture extends LXAbstractFixture {
  public final static int SIZE = 50;
  public final static int SIDE_SPACING = 1; // Space between front and back columns
  public final static float LED_SPACING = 0.016;
  
  public final float maxY = SIZE * LED_SPACING;
  public final List<LXPoint> front;
  public final List<LXPoint> back;
  
  Fixture(int x, int z) {
    List<LXPoint> front = new ArrayList<LXPoint>();
    List<LXPoint> back = new ArrayList<LXPoint>();

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
  }
}

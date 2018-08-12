import java.util.Collections;
import java.util.List;
import java.util.Arrays;

LXModel buildModel() {
    final int NUM_BEAMS = 2;
    final List<Fixture> beams = new ArrayList<Fixture>();
    
    for (int i = 0; i < NUM_BEAMS; i++) {
      beams.add(new Fixture(i*3, 1));
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
  
  Fixture(int x, int z) {
    for (float y = 0; y < SIZE; y += 1) {
      addPoint(new LXPoint(x, y * LED_SPACING, z));
    }
    
    for (float y = 0; y < SIZE; y += 1) {
      addPoint(new LXPoint(x, y * LED_SPACING, z + SIDE_SPACING));
    }
  }
}

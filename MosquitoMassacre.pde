String gridType = "DT"; // options are any combination of "V" -- velocity, "D" -- density, "T" -- temperature
boolean gridLines = false;
float boltSize = 5; // length of bolt segments

// create fluid grid
Fluid fluid;
Coil coil;

PVector prevMousePos;
int time;

void setup() {
    size(1200, 1200); // must be square or fluid sim breaks

    fluid = new Fluid(200, 5, 0.00000000001, 0.0000001);
    coil = new Coil(height/3, 100, 1);

    prevMousePos = new PVector(-1, -1);
    time = millis();
    // frameRate(60);
}

void draw() {
    background(255);

    mouseEffect();
    fluid.update();

    coil.update();
    // update shit
}

void mouseEffect() {
    PVector newMousePos = new PVector(mouseX, mouseY);

    if (0 < mouseX && mouseX < width && 0 < mouseY && mouseY < height) {
        int x = screenGrid(mouseX);
        int y = screenGrid(mouseY);

        for (int i = x-1; i <= x+1; i++) {
            for (int j = y-1; j <= y+1; j++) {
                if (x < 1 || x > fluid.N || y < 1 || y > fluid.N) continue;
                fluid.dens[i][j] += 5;
                if (mousePressed) fluid.temp[i][j] += 0.5;
            }
        }

        while (prevMousePos.dist(newMousePos) > 0.5) {
            x = screenGrid(prevMousePos.x);
            y = screenGrid(prevMousePos.y);

            PVector force = PVector.sub(newMousePos, prevMousePos).mult(0.001);

            ArrayList<Float> newForce = new ArrayList<Float>();
            newForce.add(float(x));
            newForce.add(float(y));
            newForce.add(force.x);
            newForce.add(force.y);

            fluid.forces.add(newForce);

            prevMousePos.add(PVector.sub(newMousePos, prevMousePos).mult(0.2));
        }

    }

    prevMousePos = new PVector(mouseX, mouseY);
}

int screenGrid(float p) {
    return int(1+float(ceil(fluid.N*p/width)));
}

int mouseGridX() {
    return int(1+float(ceil(fluid.N*mouseX/width)));
}

int mouseGridY() {
    return int(1+float(ceil(fluid.N*mouseY/height)));
}
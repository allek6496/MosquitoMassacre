class Mosquito {
    int maxSpeed = 10;

    PVector pos, vel, acc;

    Mosquito(float x, float y) {
        pos = new PVector(x, y);
    
        vel = PVector.fromAngle(random(0, TWO_PI)).setMag(random(1, 3));
        acc = new PVector(vel.x, vel.y).setMag(0.1);
    }

    // draw mosquito and its glow
    void draw() {
        // small circle for the body
        fill(40, 255, 60);
        noStroke();
        circle(pos.x, pos.y, 5);

        int glowRadius = 10;
        // glow around it (same code as glow around the bolts)
        for (int i = 0; i < glowRadius; i++) {
            for (int x = -i; x <= i; x++) {
                // the x value on the grid
                int iX = screenGrid(pos.x) + x;

                // don't let it draw OOB
                if (iX <= 0 || fluid.N + 2 <= iX) continue;

                // this part makes a square
                for (int y = -i; y <= i; y++) {
                    int iY = screenGrid(pos.y) + y;

                    // just don't let it draw out of bounds
                    if (iY <= 0 || fluid.N + 2 <= iY) continue;

                    // glow proportional to the distacne from the center
                    fluid.glow[iX][iY] += 4/pow(pow(abs(x), 2) + pow(abs(y), 2) + 4, 2.2);
                }
            }
        }
    }

    void update() {
        vel.rotate(random(-PI/10, PI/10));
        // vel.add(acc);

        PVector smokeVel = new PVector(
            fluid.velX[screenGrid(pos.x)][screenGrid(pos.y)],
            fluid.velY[screenGrid(pos.y)][screenGrid(pos.y)]
        ).mult(width/fluid.N*500);

        vel.add(smokeVel).limit(maxSpeed);

        // wall collision
        if (pos.x + vel.x < 0 || pos.x + vel.x > width) {
            vel.x *= -1;
            acc.x *= -1;
            pos.x = min(width, max(0, pos.x));
        }

        if (pos.y + vel.y < 0 || pos.y + vel.y > height) {
            vel.y *= -1;
            acc.y *= -1;
            pos.y = min(width, max(0, pos.y));
        }

        // coil avoidance
        float coilDist = sqrt(pow(pos.x - width/2, 2) - pow(pos.y - (height - coil.h), 2)); 
        if (coilDist < coil.radius*2) {
            PVector centerToMosquito = PVector.sub(pos, new PVector(width/2, height-coil.h));

            vel.rotate((centerToMosquito.heading() - vel.heading()) * min(1, 1.5*coil.radius / coilDist)); 
        }

        pos.add(vel);

        draw();

        // update smoke
        if (vel.y < 0) {
            ArrayList<Float> newForce = new ArrayList<Float>();
            newForce.add(float(screenGrid(pos.x)));
            newForce.add(float(screenGrid(pos.y)));
            newForce.add(0f);
            newForce.add(-vel.y/30);

            fluid.forces.add(newForce);
        }
    }

    void kill() {
        return;
    }
}
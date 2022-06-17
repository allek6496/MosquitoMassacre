class Mosquito {
    int speed = 6;

    PVector pos, vel, acc;
    boolean alive;
    float fuel;

    Mosquito(float x, float y) {
        pos = new PVector(x, y);
    
        vel = PVector.fromAngle(random(0, TWO_PI)).setMag(speed);
        acc = new PVector(vel.x, vel.y).setMag(0.1);

        alive = true;
        fuel = 0;
    }

    // draw mosquito and its glow
    void draw() {
        if (alive) {
            // small circle for the body
            fill(40, 255, 60);
            noStroke();
            circle(pos.x, pos.y, 5);

            if (gridType.indexOf("M") != -1) {
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

        // if it's dead just draw a circle on its location
        } else {
            fill(#a85c21);
            noStroke();
            circle(pos.x, pos.y, 8);

            if (fuel > 0) {
                if (gridType.indexOf("F") != -1) {
                    int fireSize = floor(fuel*8);
                    // burn around it (same code as glow above)
                    for (int i = 0; i < fireSize; i++) {
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
                                float amount = fuel*6/pow(pow(abs(x), 2) + pow(abs(y), 2) + 4, 2.2);

                                fluid.fire[iX][iY] += amount;
                                fluid.temp[iX][iY] += amount;
                                fluid.dens[iX][iY] += amount*4;
                            }
                        }
                    }
                }

                fuel -= 0.05; // last for 20 frames 
            }
        }
    }

    void update() {
        // split in two for readability
        if (alive) updateAlive();
        else updateDead();
    }

    void updateAlive() {
        int gX = screenGrid(pos.x);
        int gY = screenGrid(pos.y);
        // check if its current position is lethal (too hot or too electric)
        if (fluid.temp[gX][gY] > 0.75 || fluid.ions[gX][gY] > 0.1) {
            alive = false;
            fuel = 1; // this depeletes as the mosquito burns

            // puff of smoke and heat
            // i really like this method of fading
            for (int i = 1; i < 6; i++) {
                for (int x = -i; x <= i; x++) {
                    for (int y = -i; y <= i; y++) {
                        float amount = 2/sqrt(x*x + y*y + 1);

                        fluid.dens[gX + x][gY + y] += amount*4;
                        fluid.temp[gX + x][gY + y] += amount/2;
                    }
                }
            }

            draw();

        // if it's ok then update the position and stuff
        } else {
            vel.rotate(random(-PI/15, PI/15));
            // vel.add(acc);

            // coil avoidance
            float coilDist = sqrt(pow(pos.x - width/2, 2) + pow(pos.y - (height - coil.h), 2)); 
            if (coilDist < coil.radius*2) {
                // vector from coil center to the mosquito
                PVector centerToMosquito = PVector.sub(pos, new PVector(width/2, height-coil.h));

                // turning towards the heading of this vector points the mosquito away from the coil
                turnTowards(centerToMosquito.heading(), (coil.radius*2 - coilDist) / (coil.radius*2));
                // vel.rotate((centerToMosquito.heading() - vel.heading()) * min(1, 1.5*coil.radius / coilDist)); 
            }

            // wall avoidance
            float buffer = 100;
            // left wall
            if (pos.x < buffer) {
                // turn right (towards 0/TWO_PI)
                turnTowards(TWO_PI, (buffer - pos.x)/buffer);
            }

            // top wall
            if (pos.y < buffer) {
                // turn down (towards PI/2)
                turnTowards(PI/2, (buffer - pos.y)/buffer);
            }

            // right wall
            if (width - buffer < pos.x) {
                // turn left (towards PI)
                turnTowards(PI, (buffer - (width - pos.x))/buffer);
            }

            // bottom wall
            if (height - buffer < pos.y) {
                // turn up (towards 3*PI/2) 
                turnTowards(3*PI/2, (buffer - (height - pos.y))/buffer);
            }
            
            // mosquito avoidance
            // turn away from the closest mosquito
            if (mosquitos.size() >= 2) {
                // find the closest mosquito 
                Mosquito closest = null;
                for (Mosquito mosquito : mosquitos) {
                    if (mosquito != this) {
                        if ((closest != null && pos.dist(mosquito.pos) < pos.dist(closest.pos)) || 
                            closest == null) {

                            closest = mosquito;
                        }
                    }
                }

                // vector from other mosquito to this one
                PVector seperation = PVector.sub(pos, closest.pos);
                turnTowards(seperation.heading(), (buffer - seperation.mag())/(buffer*6));
            }

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

            // PVector m2m = PVector.sub(new PVector(mouseX, mouseY), pos);
            // turnTowards(m2m.heading(), 0.5);

            PVector smokeVel = new PVector(
                fluid.velX[gX][gY],
                fluid.velY[gX][gY]
            ).mult(width/fluid.N*300).limit(speed*2);
            
            pos.add(vel).add(smokeVel);

            draw();

            // push smoke backwards to fly forwards (this is a bit jank because that backdraft pulls the mosquito back as well)
            ArrayList<Float> newForce = new ArrayList<Float>();
            newForce.add(float(screenGrid(pos.x)));
            newForce.add(float(screenGrid(pos.y)));
            newForce.add(-vel.x/100);
            newForce.add(-vel.y/100);

            fluid.forces.add(newForce);
        }
    }

    void updateDead() {
        int gX = screenGrid(pos.x);
        int gY = screenGrid(pos.y);

        PVector smokeVel = new PVector(
            fluid.velX[gX][gY],
            fluid.velY[gX][gY]
        ).mult(width/fluid.N*1000);

        // wall collision
        if (pos.x + vel.x < 5 || pos.x + vel.x > width-5) {
            vel.x *= -1;
            pos.x = min(width, max(0, pos.x));
        }

        if (pos.y + vel.y < 5 || pos.y + vel.y > height-10) {
            vel.y *= -0.2;
            pos.y = min(width, max(0, pos.y));
        } 

        // friction along the bottom, quarter horizontal and halve vertical velocities
        if (pos.y > height - 10) {
            vel.x *= 0.05;
        }

        // determine the difference in speed
        smokeVel.sub(vel);

        vel.add(smokeVel).add(0, 3).limit(speed*3);
        pos.add(vel);        

        draw();
    }

    // angle E (0, TWO_PI}
    // amount == 1 turns fully towards the angle
    void turnTowards(float angle, float amount) {

        // heading() works oddly, I prefer the normal range of 0-TWO_PI
        float heading = vel.heading();
        if (heading < 0) heading = TWO_PI + heading;

        // i think it overshoots if you set amount > 1
        if (amount > 1) amount = 1;

        if (angle < 0) angle += TWO_PI;

        float opposite = angle - PI;
        if (opposite <= 0) opposite += TWO_PI;

        // there might be a smaller way to do this but this seems easiest
        if (angle <= PI) {
            // if it's smaller than opposite, approach the desired angle
            if (heading < opposite) vel.rotate((angle - heading)*amount);
            // otherwise, you have to approach the angle + TWO_PI in order to turn in the optimal direction
            else vel.rotate((angle+TWO_PI - heading)*amount);
        
        // logic is backwards if the desired angle is above PI
        } else {
            if (heading > opposite) vel.rotate((angle - heading)*amount);
            else vel.rotate((angle-TWO_PI - heading)*amount);
        }
    }
}
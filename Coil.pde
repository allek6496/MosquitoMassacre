
class Coil {
    // coil constants
    float minCharge = 5; // charge before a bolt can possibly happen
    float maxPower = 6;
    float minPower = 0.5;

    float h;
    float radius;
    float power; // rate of charge buildup

    float charge;
    ArrayList<Bolt> bolts;

    Coil(float height, float radius) {
        this.h = height;
        this.radius = radius;
        this.power  = (maxPower + minPower) / 2;

        this.charge = 0;
        bolts = new ArrayList<Bolt>();
    }

    void update() {
        // useful values for grid calculations
        int gridCenterX = screenGrid(width/2); // center of the coil horizontally
        int gridRadius = screenGrid(radius); // radius in squares
        float d = float(width)/fluid.N; // width of a grid square
        
        // draw the coil
        // start with the body column
        pushMatrix();// make sure to draw behind the head (stroke schenanigans)
        translate(0, 0, -2);
        rectMode(CENTER);
        noStroke();
        fill(75);
        rect(width/2, height - h/2, radius, h); 

        // coil wraps
        noFill();
        stroke(200, 0, 40);
        strokeWeight(2);
        float theta = tan(1/4.0);
        for (int y = int(height-radius*2); y > height - h - radius*2; y -= 6) {
            arc(width/2, y, radius*4, radius*4, PI/2 - theta, PI/2 + theta);
        }
        popMatrix();

        // shading
        for (int x = -gridRadius/2-1; x <= gridRadius/2; x++) {
            noStroke();
            rectMode(CORNERS);
            fill(0, 400*abs(gridRadius/4 - x)/gridRadius);
            rect(width/2 + x*d, height - h, width/2 + (x + 1)*d, height);
        }

        // head of the coil (circle for ez math later), draw on the grid rather than with a circle
        int gridCenterY = screenGrid(height-h);

        // x and y are offsets from the center of the head
        for (int x = -gridRadius; x <= gridRadius; x++) {
            for (int y = -gridRadius; y <= gridRadius; y++) {
                // distance from head center
                float dist = sqrt(x*x + y*y);
                
                // if it's within the circle 
                if (dist <= gridRadius) {
                    // fill with brightness coresponding to how close it is to the shine 
                    float dShine = sqrt(
                        pow(x + gridCenterX - screenGrid(width/2 + radius/2.2), 2) + 
                        pow(y + gridCenterY - screenGrid(height - (h + radius/2)), 2)
                    );

                    noStroke();
                    fill(255 - dShine * 255 / (2*gridRadius) - 128*pow(dist/gridRadius, 2));

                    rectMode(CENTER);
                    rect((x+gridCenterX-0.5)*d, (y+gridCenterY-0.5)*d, d, d); 
                }
            }
        }

        charge += power;
        
        // chance to add a bolt
        if (random(1) < log(charge - minCharge + 1)/log(25)) {
            float boltTheta = random(TWO_PI-4*theta) + (PI/2 + 2*theta);
            if (boltTheta > TWO_PI) boltTheta -= TWO_PI;
            bolts.add(new Bolt(width/2 + cos(boltTheta)*radius, height - (h - sin(boltTheta)*radius), charge, boltTheta));

            charge = 0;
        }

        // loop through all the bolts and remove them if they're finished
        for (int i = bolts.size() - 1; i >= 0; i--) {
            if (!bolts.get(i).update()) {
                bolts.remove(i);
            }
        }

        // charge bar
        rectMode(CORNER);
        noStroke();
        color a = color(#00144c);
        color b = color(#07fcfc);
        for (int y = height; y >= height - h + radius*3/2; y -= d) {
            fill(lerpColor(a, b, (height - y)/(h-radius*3/2)));
            rect((gridCenterX - 2)*d, y-d, 3*d, d);
        }

        // charge indicator
        fill(0);
        rect((gridCenterX - 2)*d, height - (h - radius*3/2)*power/maxPower, 3*d, d);

        // small plus
        fill(b);
        rect((gridCenterX - 1)*d, height - h + radius*3/2 - 4*d, 1*d, d*3);
        rect((gridCenterX - 2)*d, height - h + radius*3/2 - 3*d, 3*d, d);
    }

    // return true if clicked inside of charge box
    boolean mouseClicked() {
        int gridCenterX = screenGrid(width/2); // center of the coil horizontally
        int gridRadius = screenGrid(radius); // radius in squares
        float d = float(width)/fluid.N; // width of a grid square
        

        if ((gridCenterX - 2)*d < mouseX && mouseX < (gridCenterX + 1)*d &&
            height - h + radius*3/2 < mouseY && mouseY < height) {
            
            this.power = maxPower*(height - mouseY)/(h - radius*3/2);

            return true;
        }

        return false;
    }
}
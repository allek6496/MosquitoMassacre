
class Coil {
    // coil constants
    float minCharge = 10; // charge before a bolt can possibly happen

    float h;
    float radius;
    float power; // rate of charge buildup

    float charge;
    ArrayList<Bolt> bolts;

    Coil(float height, float radius, float power) {
        this.h = height;
        this.radius = radius;
        this.power  = power;

        this.charge = 0;
        bolts = new ArrayList<Bolt>();
    }

    void update() {
        // draw the coil
        // start with the body column
        rectMode(CENTER);
        fill(75);
        rect(width/2, height - h/2, radius, h); 

        // coil wraps
        noFill();
        stroke(200, 0, 40);
        strokeWeight(2);
        float theta = tan(1/4.0);
        println(theta);
        for (int y = int(height-radius*2); y > height - h - radius*2; y -= 6) {
            arc(width/2, y, radius*4, radius*4, PI/2 - theta, PI/2 + theta);
        }

        // push it ahead to ensure it's on top of everything
        pushMatrix();
        translate(0, 0, 1);

        // head of the coil (circle for ez math later)
        stroke(150);
        fill(150);
        circle(width/2, height - h, radius*2);
        
        // shine for effect
        noStroke();
        fill(215);
        circle(width/2 + radius/2.2, height - (h + radius/2), radius/6);
        popMatrix();

        charge += power;
        
        // chance to add a bolt
        if (charge - minCharge > random(0.5)*pow(charge - minCharge, 2)) {
            float boltTheta = random(TWO_PI-2*theta) + (PI/2 + theta);
            if (boltTheta > TWO_PI) boltTheta -= TWO_PI;
            bolts.add(new Bolt(width/2 + cos(boltTheta)*radius, h - sin(boltTheta)*radius, charge));

            charge = 0;
        }
    }
}
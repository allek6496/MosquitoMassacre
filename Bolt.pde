// recursive class holding a tree of electricity
class Bolt {
    float headX, headY;
    float len;
    float charge; // charge held in this bolt plus all of its children

    Bolt[] children;

    // main constructor
    Bolt(float headX, float headY, float charge) {
        this.headX = headX;
        this.headY = headY;
        this.charge = charge;

        children = new Bolt[2]; // up to 2 children
    

    }

}
    // // child constructor
    // Bolt(float headX, float headY, float len, float charge) {
    //     this(headX, headY, charge);

    //     this.len = len;
    // }
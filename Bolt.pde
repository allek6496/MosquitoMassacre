// recursive class holding a tree of electricity
class Bolt {
    // global bolt settings
    float len = 10;
    float speed = 10; // how many bolts to spawn per frame, until charge is depleted
    float dissipation = 0.05; // how much charge is naturally lost per bolt segment

    float headX, headY;
    float charge; // charge held in this bolt plus all of its children

    float angle;
    Bolt parent;
    Bolt[] children;

    // main constructor
    Bolt(float headX, float headY, float charge) {
        this.headX = headX;
        this.headY = headY;
        this.charge = charge;

        this.angle = 0; // TODO: normal of coil

        this.parent = null;
        children = new Bolt[2]; // up to 2 children
    }

    // child constructor
    // depth: how many parents this has in the tree
    Bolt(float headX, float headY, float charge, Bolt parent, int depth) {
        this(headX, headY, charge);

        this.parent = parent;
    }

    void update() {
        // if it's the head node, kick off the process
        if (parent == null) {
            // if it doesn't have children yet, make ONE (no starting branched, that would look odd)
            if (children[0] == null) {
                addChild();
            } else {
                children[0].update();
            }
        } else {

        }
    }

    // adds a child to this branch
    void addChild() {
        PVector dir = direct();

        if (children[0] == null) {
            // children[0] = new Bolt()
        }

    }

    // the direction a child will go in, including forces from all other bolts in this tree (ignore other trees) and up to one child (for second child calculation)
    PVector direct() {
        return new PVector(0, 0);
    }
}
import java.util.Set;

// recursive class holding a tree of electricity
class Bolt {
    // global bolt settings
    float len = boltSize;
    int speed = 20; // how many bolts to spawn per frame, until charge is depleted
    float dissipation = 0.06; // how much charge is naturally lost per bolt segment
    float smokeAmount = 0.5;
    float heat = 0.3;

    PVector pos;
    PVector head;
    float charge; // charge held in this bolt plus all of its children
    int depth; // if it's the head bolt, this is the number of updates that have happened

    float angle;
    Bolt parent;
    Bolt[] children;

    // main constructor
    Bolt(float headX, float headY, float charge, float angle) {
        this.pos = new PVector(headX, headY);
        this.head = PVector.add(pos, PVector.fromAngle(angle).setMag(len));

        this.charge = charge;

        this.depth = 0;
        this.angle = angle; 

        this.parent = null;
        children = new Bolt[2]; // up to 2 children
    }

    // child constructor
    // depth: how many parents this has in the tree
    Bolt(float headX, float headY, float charge, float angle, Bolt parent, int depth) {
        this(headX, headY, charge, angle);

        this.depth = depth;
        this.parent = parent;
    }

    // TODO: glow into air and moreso smoke
    void draw() {
        stroke(225, 225, 255);
        strokeWeight(ceil(sqrt(4*charge)));

        line(pos.x, pos.y, head.x, head.y);

        if (gridType.indexOf("I") != -1) {
            int gX = screenGrid(head.x);
            int gY = screenGrid(head.y);

            for (int i = 0; i < 12; i++) {
                for (int x = -i; x <= i; x++) {
                    for (int y = -i; y <= i; y++) {
                        int iX = max(1, min(gX + x, fluid.N+1));
                        int iY = max(1, min(gY + y, fluid.N+1));
                        fluid.ions[iX][iY] += charge/(4*coil.minCharge)/(3*pow(i, 3)+1);
                    }
                }
            }
        }
    }

    // parent update
    boolean update() {
        draw();

        if (depth == 0) { // first update
            addChildren(0);
        }

        depth += speed;

        boolean keepUpdating = children[0].update(depth);
        if (children[1] != null) keepUpdating |= children[1].update(depth);
        
        return keepUpdating;
    }

    // child update
    boolean update(int targetDepth) {
        draw();

        if (depth < targetDepth) {
            // if it hasn't got a child yet and is before the current depth cap, add 1 or 2 children
            if (children[0] == null) {
                addChildren(targetDepth);

                if (children[0] == null) return false; // return false when it can't go any further (out of charge)

            // small chance to add a second child afterwards
            } else if (children[1] == null && charge >= dissipation*10 && random(1) < 0.0003*len) {
                addChild(random(0.1, 0.25), targetDepth);
            }
        } else if (depth == targetDepth) return true;           

        // whether there is more depth to be had
        boolean keepUpdating = false;
        if (children[0] != null) keepUpdating |= children[0].update(targetDepth);
        if (children[1] != null) keepUpdating |= children[1].update(targetDepth);

        return keepUpdating;
    }

    // add one child with a small chance of two
    void addChildren(int targetDepth) {
        if (children[0] == null) { // currently no point in adding if there's already one child. This could be changed in the future
            if (random(1) < 0.005*len) {
                float split = random(0.1, 0.9);
                addChild(split, targetDepth);
                addChild(1-split, targetDepth);
            } else addChild(1, targetDepth);
        }
    }

    // adds a child to this branch. super annoying to have to pass targetDepth all the way through, but idk how else to do it
    void addChild(float amount, int targetDepth) {
        if (head.x < 0 || width < head.x ||
            head.y < 0 || height < head.y) return;

        float newCharge;
        newCharge = charge*amount - dissipation;

        if (newCharge <= 0) return;

        float dir = direct();

        // if this is branching off of an old chunk, keep the depth in check
        int newDepth = depth + 1;

        if (depth < targetDepth - speed) newDepth = targetDepth - speed; 

        // yes head is being called twice, I don't care to fix that
        Bolt newBolt = new Bolt(head.x, head.y, newCharge, dir, this, newDepth);

        // whether or not a new bolt was successfully made
        boolean used = false;
        if (children[0] == null) {
            children[0] = newBolt;
            used = true;

        } else if (children[1] == null) {
            children[1] = newBolt;
            used = true;
        }

        
        // (removed) do the math for intersection of line with grid

        // or just create smoke at the head (this is better in mose cases lol)
        if (used) {
            fluid.dens[screenGrid(head.x)][screenGrid(head.y)] += smokeAmount*charge;
            fluid.temp[screenGrid(head.x)][screenGrid(head.y)] += heat*charge;
        }
    }

    // the direction a child will go in, including forces from all other bolts in this tree and up to one child (for second child calculation)
    float direct() {
        // there's no previous node to repel from, so just make it in the same direction
        if (parent == null) {
            return angle;
        }

        // repel from up to one child (for second child calculation)
        PVector force = new PVector(0, 0);
        if (children[0] != null) 
            force = getForce(children[0]).mult(2); 

        // find the root for boltRepulsion calculation
        Bolt root = this;
        while (root.parent != null) {
            root = root.parent;
        } 

        // adds the repulsion from this whole bolt
        force.add(boltRepulsion(root));

        // adds the repulsion from every other bolt
        for (Bolt bolt : coil.bolts) {
            if (bolt != root) force.add(boltRepulsion(bolt));
        }

        // repel strongly from the head of the coil
        PVector fromCoil = PVector.sub(head, new PVector(width/2, height - coil.h));
        fromCoil.setMag(50*this.charge / pow((fromCoil.mag() - coil.radius), 2));
        force.add(fromCoil);

        // attract slightly towards mosquitos
        force.add(targetAttract());

        // smoke attract (small effect, attempts to keep it within the smoke if possible)
        // sample smoke levels ahead, left and right, and turn appropriately 
        float turnAmount = PI/6;
        force.setMag(len);

        // find the positions that would result if the bolt were moved left, right, and equal to where the force is currently taking it
        force.rotate(-turnAmount);
        PVector leftHead = PVector.add(pos, force);
        force.rotate(turnAmount);

        PVector straightHead = PVector.add(pos, force);

        force.rotate(turnAmount);
        PVector rightHead = PVector.add(pos, force);
        force.rotate(-turnAmount);

        // constrain it within the grid
        PVector[] directions = {leftHead, straightHead, rightHead};
        for (PVector p : directions) {
            p.x = min(max(p.x, 0), width);
            p.y = min(max(p.y, 0), height);
        }

        // find the density levels at each of these positions
        float leftGas = fluid.dens[screenGrid(leftHead.x)][screenGrid(leftHead.y)];
        float straightGas = fluid.dens[screenGrid(straightHead.x)][screenGrid(straightHead.y)];
        float rightGas = fluid.dens[screenGrid(rightHead.x)][screenGrid(rightHead.y)];

        // turn based off how much of a difference it is?
        if (straightGas == max(leftGas, straightGas, rightGas)) {
            // do nothing
        } else if (leftGas > rightGas) {
            force.add(PVector.fromAngle(force.heading() - turnAmount/2).mult((leftGas - straightGas)*3));
        } else {
            force.add(PVector.fromAngle(force.heading() + turnAmount/2).mult((rightGas - straightGas)*3));
        }

        force.rotate(random(-PI/15, PI/15));
        return force.heading(); // magnitude of this isn't used
    }

    // pulls the bolt towards mosquitos
    PVector targetAttract() {
        PVector force = new PVector(0, 0);

        for (Mosquito mosquito : mosquitos) {
            if (mosquito.alive) {
                PVector newForce = PVector.sub(mosquito.pos, this.head);
                newForce.setMag(10*this.charge / pow(newForce.mag(), 2));

                force.add(newForce);
            }
        }
        return force;
    }

    // recursive function to get the net repulsion from this whole bolt (excluding up to one possible child)
    // must pass in the root bolt
    PVector boltRepulsion(Bolt root) {
        if (root == this) return new PVector(0, 0);

        PVector force = getForce(root);

        if (root.children[0] != null) force.add(boltRepulsion(root.children[0]));
        if (root.children[1] != null) force.add(boltRepulsion(root.children[1]));
        
        return force;
    }

    // gets the force from another bolt onto this one
    PVector getForce(Bolt bolt) {
        PVector force = PVector.sub(this.head, bolt.head);
        force.setMag(2*this.charge * bolt.charge / pow(force.mag(), 2)); // Change the /10 to adjust strength
        if (Float.isNaN(force.mag())) force = new PVector(0, 0);
        return force;
    }
}
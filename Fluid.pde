// Algorithms from: https://www.dgp.toronto.edu/public_user/stam/reality/Research/pdf/GDC03.pdf
// I understand all the code, but no reason to make it from scratch

// TODO: remove swapping altogether 
class Fluid {
    int N; // number of cells across the screen (must be square)
    float dt; // dt seems to be speed of processing
    float viscosity;
    float diffusion;

    // [x][y]
    float[][] dens;
    float[][] temp;
    float[][] velX;
    float[][] velY;
    
    ArrayList<ArrayList<Float>> forces; // list of [x, y, forceX, forceY] to specifiy location and direction of force

    Fluid(int N, float dt, float viscosity, float diffusion) {
        this.N = N;
        this.dt = dt;

        this.viscosity = viscosity;
        this.diffusion = diffusion;

        // 1-N on-screen, 0 and N+1 off-screen
        this.dens = new float[N+2][N+2];
        this.temp = new float[N+2][N+2];
        this.velX = new float[N+2][N+2];
        this.velY = new float[N+2][N+2];
        this.forces = new ArrayList<ArrayList<Float>>();
        // temp = new int[N+2][N+2];
    }

    void update() {       
        // broken up into procedures for simplicity, and because that's how the paper did it
        velUpdate();
        forces = new ArrayList<ArrayList<Float>>(); // clear forces after every frame

        densUpdate();
        
        draw();
    }

    void draw() {
        float d = float(width)/N;

        for (int x = 1; x <= N; x++) {
            // vertical lines
            if (gridLines) {
                strokeWeight(2);
                line(x*d, 0, x*d, height);
            }

            for (int y = 1; y <= N; y++) {
                if (gridType.indexOf("V") != -1) {
                    stroke(0);
                    strokeWeight(2);

                    PVector v = new PVector(velX[x][y], velY[x][y]);

                    v.setMag(d/2*min(1, v.mag()*10));
                    line((x-0.5)*d,       (y-0.5)*d, 
                         (x-0.5)*d + v.x, (y-0.5)*d + v.y);
                } 

                if (gridType.indexOf("D") != -1) {
                    rectMode(CENTER);
                    
                    noStroke();
                    fill(0, 0, 0, min(dens[x][y], 1.5)*180);
                    rect((x-0.5)*d, (y-0.5)*d, d, d);
                }

                if (gridType.indexOf("T") != -1) {
                    rectMode(CENTER);
                    noStroke();
                    fill(255, 0, 0, min(sqrt(temp[x][y]), 1)*255);;
                    rect((x-0.5)*d, (y-0.5)*d, d, d); 
                }

                // horizontal lines
                if (gridLines && x == 1) {
                    stroke(0);
                    strokeWeight(2);
                    line(0, y*d, width, y*d);
                }
            }
        }
    }

    void velUpdate() {
        // second array to hold the new values safely
        float[][] velNewX = new float[N+2][N+2];
        float[][] velNewY = new float[N+2][N+2];

        // add forces
        for (ArrayList<Float> force : forces) {
            velX[int(force.get(0))][int(force.get(1))] += force.get(2);
            velY[int(force.get(0))][int(force.get(1))] += force.get(3);
        }
        
        // temperature
        for (int x = 1; x <= N; x++) {
            for (int y = 1; y <= N; y++) {
                velY[x][y] -= dens[x][y] * dens[x][y] * (temp[x][y] - 0.1) * 0.025;
            }
        }

        diffuse(velNewX, velX, viscosity, 1);
        diffuse(velNewY, velY, viscosity, 2); 

        project(velX, velY);

        // move velocity along the velocity
        advect(velX, velNewX, 1); advect(velY, velNewY, 2);

        project(velX, velY);

        // vorticity confinement
        float vorticity = 0.05;
        for (int x = 2; x <= N-1; x++) {
            for (int y = 2; y <= N-1; y++) {
                float dx = abs(curl(x, y-1)) - abs(curl(x, y+1));
                float dy = abs(curl(x+1, y)) - abs(curl(x-1, y));
                float len = sqrt(dx*dx + dy*dy) + 0.00001; // not sure what len is

                dx = vorticity/len*dx;
                dy = vorticity/len*dy;

                velX[x][y] += dt*curl(x, y)*dx;
                velY[x][y] += dt*curl(x, y)*dy;
            }
        }
    }

    void densUpdate() {
        float[][] densNew = new float[N+2][N+2];
        float[][] tempNew = new float[N+2][N+2];

        // add sources or whatever
        diffuse(densNew, dens, diffusion, 0);
        diffuse(tempNew, temp, diffusion, 0);
        // swap(dens, densNew);

        advect(dens, densNew, 0);
        advect(temp, tempNew, 0);
        // swap(dens, densNew);
    }

    // here d is anything, to be filled with the diffused values
    void diffuse(float[][] d, float[][] d0, float diffRate, int boundType) {
        float a = dt*diffRate*N*N; // this is one of the few parts I don't get, why *N*N? 

        for (int k = 0; k < 8; k++) {
            for (int x = 1; x <= N; x++) {
                for (int y = 1; y <= N; y++) {
                    d[x][y] = (d0[x][y] + a*(d[x-1][y] + d[x+1][y] + d[x][y-1] + d[x][y+1]))/(1.0+4*a);
                    // d[x][y] = random(-1, 1);
                }
            }

            boundUpdate(d, boundType);
        }
    }

    // this one is super complicated, and i understand what it's doing but not really how
    void project(float[][] velX, float[][] velY) {
        // TODO: understand this code

        float[][] p = new float[N+2][N+2]; // seems to hold a modified field that the final field comes from
        float[][] div = new float[N+2][N+2]; // divergence at each point

        // height of a cell, assuming the screen is 1 wide
        // that's what it is but what's the point of it, it's multiplied by the vector field div, and divided out at the end
        float h = 1.0/N;

        for (int x = 1; x <= N; x++) {
            for (int y = 1; y <= N; y++) {
                // this seems to 
                div[x][y] = -0.5f*(velX[x+1][y] - velX[x-1][y] +
                                  velY[x][y+1] - velY[x][y-1])/N;
                p[x][y] = 0;
            }
        }

        boundUpdate(div, 0); // smooths the divergence across the edges
        // boundUpdate(p, 0); // just fills the corners with 0 lol

        for (int k = 0; k < 20; k++) {
            for (int x = 1; x <= N; x++) {
                for (int y = 1; y <= N; y++) {
                    p[x][y] = (div[x][y] + p[x-1][y] + p[x+1][y] +
                                           p[x][y-1] + p[x][y+1])/4;
                }
            }

            boundUpdate(p, 0);
        }

        for (int x = 1; x <= N; x++) {
            for (int y = 1; y <= N; y++) {
                velX[x][y] -= 0.5f*(p[x+1][y] - p[x-1][y])*N;
                velY[x][y] -= 0.5f*(p[x][y+1] - p[x][y-1])*N;
            }
        }

        boundUpdate(velX, 1); boundUpdate(velY, 2);
    }

    // d is the element to advect based on the two velocity fields, continuous used only in boundUpdate
    void advect(float[][] d, float[][] d0, int boundType) {
        for (int x = 1; x <= N; x++) {
            for (int y = 1; y <= N; y++) {
                // x and y position of the source of the new value
                float sX = x - N*dt*velX[x][y]; 
                // println(x, sX);
                float sY = y - N*dt*velY[x][y];

                // bind the 2x2 box around sX, sY within the 0-N+1 grid
                sX = min(max(sX, 0.5), N+0.5); sY = min(max(sY, 0.5), N+0.5); 

                // x and y of the 2x2 box around sX and sY
                int x0 = floor(sX); int x1 = x0+1;
                int y0 = floor(sY); int y1 = y0+1;

                // distance to each of the boxes in the 2x2 grid
                float dx1 = sX-x0; float dx0 = 1 - dx1; 
                float dy1 = sY-y0; float dy0 = 1 - dy1;

                if (false && x == mouseGridX() && y == mouseGridY()) {
                    stroke(255, 0, 0);
                    fill(0, 0);
                    rectMode(CENTER);

                    // println(sX, x0, sY, y0);
                    // println(dx0, dx1, dy0, dy1);
                    // println();
                    // println(velX[x][y], velY[x][y]);

                    float dS = float(width)/N;
                    // rect(dS*x, dS*y, 2*dS, 2*dS);

                    circle(sX*dS, sY*dS, dS);
                }

                // the new value is the 2d interpolated value from this grid
                d[x][y] = dx0*(dy0*d0[x0][y0] + dy1*d0[x0][y1]) + 
                          dx1*(dy0*d0[x1][y0] + dy1*d0[x1][y1]);
            }
        }

        boundUpdate(d, boundType);
    }

    // boundType == 1 is for X vectors, 2 is for Y vectors and 0 is continuous (carried values)
    void boundUpdate(float[][] d, int boundType) {
        for (int i = 1; i <= N; i++) {
            int mod = 1; 

            // left-right boundaries
            if (boundType == 1) mod = -1;
            d[0][i] = d[1][i]*mod;
            d[N+1][i] = d[N][i]*mod;

            // top-bottom boundaries
            if (boundType == 2) mod = -1;
            else mod = 1;
            d[i][0] = d[i][1]*mod;
            d[i][N+1] = d[i][N]*mod;
        }

        // corners
        d[0][0] = (d[1][0] + d[0][1])/2;
        d[0][N+1] = (d[0][N] + d[1][N+1])/2;
        d[N+1][0] = (d[N][0] + d[N+1][1])/2;
        d[N+1][N+1] = (d[N][N+1] + d[N+1][N])/2;
    }

    // returns the curl at a particular location
    float curl(int x, int y) {
        return velX[x][y+1] - velX[x][y-1] + velY[x-1][y] - velY[x+1][y];
    }

    void swap(float[][] a, float[][] b) {
        float[][] temp = new float[N+2][N+2];
        temp = a;
        a = b;
        b = temp;
    }
}
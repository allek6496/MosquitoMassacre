// Algorithms from: https://www.dgp.toronto.edu/public_user/stam/reality/Research/pdf/GDC03.pdf
// I understand all the code, but no reason to make it from scratch

// TODO: remove swapping altogether 
class Fluid {
    int N; // number of cells across the screen (must be square, could be a global variable but oh well)
    float dt; 
    float viscosity;
    float diffusion;

    // so many grids wtf space complexity where?
    // [x][y]
    float[][] dens;
    float[][] temp;
    float[][] ions;
    float[][] glow;
    float[][] fire;
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
        this.ions = new float[N+2][N+2]; // lightning ionization 
        this.glow = new float[N+2][N+2]; // mosquito glow
        this.fire = new float[N+2][N+2];
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
        ions = new float[N+2][N+2];
        glow = new float[N+2][N+2];
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
                rectMode(CENTER);
                noStroke();

                // it would be easier to just add the colors, but that math is a little 

                // density
                if (gridType.indexOf("D") != -1) {
                    fill(100, 100, 100, min(dens[x][y], 1.5)*180);
                    rect((x-0.5)*d, (y-0.5)*d, d, d);
                }

                // heat
                if (gridType.indexOf("T") != -1) {
                    fill(255, 0, 0, min(sqrt(temp[x][y]), 1)*255);;
                    rect((x-0.5)*d, (y-0.5)*d, d, d); 
                }

                // glow from mosquitos
                if (gridType.indexOf("M") != -1) {
                    fill(80, 255, 100, min(sqrt(glow[x][y]) * pow(dens[x][y] + 0.1, 0.25), 1)*255);
                    rect((x-0.5)*d, (y-0.5)*d, d, d); 
                }

                // fire glow
                if (gridType.indexOf("F") != -1) {
                    fill(252, 206, 108, min(sqrt(fire[x][y]) * pow(dens[x][y], 0.5), 1)*255);
                    rect((x-0.5)*d, (y-0.5)*d, d, d);
                }

                // ionization level
                if (gridType.indexOf("I") != -1) {
                    fill(180, 150, 255, min(sqrt(ions[x][y]) * pow(dens[x][y], 1), 1)*255);
                    rect((x-0.5)*d, (y-0.5)*d, d, d); 
                }

                // velocity lines
                if (gridType.indexOf("V") != -1) {
                    stroke(0);
                    strokeWeight(1);

                    PVector v = new PVector(velX[x][y], velY[x][y]);

                    v.setMag(2*d*min(1, v.mag()*50));
                    line((x-0.5)*d,       (y-0.5)*d, 
                         (x-0.5)*d + v.x, (y-0.5)*d + v.y);
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
            if (0 <= force.get(0) && force.get(0) <= N+1 &&
                0 <= force.get(1) && force.get(1) <= N+1) {

                velX[int(force.get(0))][int(force.get(1))] += force.get(2);
                velY[int(force.get(0))][int(force.get(1))] += force.get(3);
            }
        }
        
        // temperature/gravity (density/temp reduction should probably be elsewhere but this is convienent)
        for (int x = 1; x <= N; x++) {
            for (int y = 1; y <= N; y++) {
                velY[x][y] -= pow(dens[x][y], 0.25) * (temp[x][y] - 0.01) * 0.0005;
                temp[x][y] /= 1.05; // gradually remove temperature (somewhat cheaty, but should make it look better)
                dens[x][y] /= 1.005;
                fire[x][y] /= 1.25;
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

        project(velX, velY);
    }

    void densUpdate() {
        float[][] densNew = new float[N+2][N+2];
        float[][] tempNew = new float[N+2][N+2];
        float[][] fireNew = new float[N+2][N+2];

        // add sources or whatever
        diffuse(densNew, dens, diffusion, 0);
        diffuse(tempNew, temp, diffusion, 0);
        diffuse(fireNew, fire, diffusion, 0);
        // swap(dens, densNew);

        advect(dens, densNew, 0);
        advect(temp, tempNew, 0);
        advect(fire, fireNew, 0);
        // swap(dens, densNew);
    }

    // here d is anything, to be filled with the diffused values
    void diffuse(float[][] d, float[][] d0, float diffRate, int boundType) {
        float a = dt*diffRate*N*N; // this is one of the few parts I don't get, why *N*N? 

        for (int k = 0; k < 20; k++) {
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
        boundUpdate(p, 0); // just fills the corners with 0 lol

        for (int k = 0; k < 10; k++) {
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

                    float dS = float(width)/N;

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
            float mod = 1; 

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
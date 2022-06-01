// Algorithms from: https://www.dgp.toronto.edu/public_user/stam/reality/Research/pdf/GDC03.pdf
// I understand all the code, but no reason to make it from scratch
class Fluid {
    int N; // number of cells across the screen (must be square)
    float viscosity;
    float diffusion;

    // [x][y]
    float[][] dens;
    float[][] velX;
    float[][] velY;

    Fluid(int N) {
        this.N = N;
        float viscosity = 0;
        float diffusion = 0.3;

        // 1-N on-screen, 0 and N+1 off-screen
        dens = new float[N+2][N+2];
        velX = new float[N+2][N+2];
        velY = new float[N+2][N+2];
        // temp = new int[N+2][N+2];
    }

    void update(float dt) {       
        velUpdate(dt);
        // densUpdate();
        
        // draw();
    }

    void velUpdate(float[][] velX, float[][] velY, float dt) {
        // add forces & temperature

        velNewX = new float[N+2][N+2];
        velNewY = new float[N+2][N+2];
        
        diffuse(velX, velNewX, diffusion, dt); swap(velX, velNewX);
        diffuse(velY, velNewY, diffusion, dt); swap(velY, venNewY);

        // project();
        
        advect();
        
        // project();
    }

    // here d is anything
    void diffuse(float[][] d, float[][] d0, float diffRate, float dt) {
        float a = dt*diffRate*N*N; // this is one of the few parts I don't get, why *N*N? 

        for (int k = 0; k < 20; k++) {
            for (int x = 1; x <= N; x++) {
                for (int y = 1; y <= N; y++) {
                    d[x][y] = (d0[x][y] + a*(d[x-1][y] + d[x+1][y] + d[x][y-1] + d[x][y+1]))/(1+4*a);
                }
            }

            boundUpdate(d, true);
        }
    }

    // d is the element to advect based on the two velocity fields, continuous used only in boundUpdate
    void advect(float[][] d, float[][] d0, float[][] velX, float[][] velY, boolean continuous, float dt) {
        float dt0 = dt*N;

        for (int x = 1; x <= N; x++) {
            for (int y = 1; y <= N; y++) {
                // x and y position of the source of the new value
                float sX = x - dt0*velX[x][y]; 
                float sY = y - dt0*velY[x][y];

                // bind the 2x2 box around sX, sY within the 0-N+1 grid
                sX = min(max(sX, 0.5), N + 0.5); sY = min(max(sY, 0.5), N+0.5); 

                // x and y of the 2x2 box around sX and sY
                int x0 = int(sX); int x1 = x0+1;
                int y0 = int(sY); int y1 = y0+1;

                // distance to each of the boxes in the 2x2 grid
                float dx0 = x-x0; float dx1 = 1 - dx0; 
                float dy0 = y-y0; float dy1 = 1 - dy0;

                // the new value is the 2d interpolated value from this grid
                d[x][y] = dx0*(dy0*d0[x0][y0] + dy1*d0[x0][y1]) + 
                          dx1*(dy0*d0[x1][y0] + dy1*d0[x1][y1]);
            }
        }

        boundUpdate(d, continuous);
    }

    void boundUpdate(float[][] d, boolean continuous) {
        for (int i = 1; i <= N; i++) {
            // continuous means the boundary is the closest square, false means it's opposite      
            int mod = 0; 
            if (continuous) {
                mod = 1;
            } else {
                mod = -1;
            }

            // left-right boundaries
            d[0][i] = d[1][i]*mod;
            d[N+1][i] = d[N][i]*mod;

            // top-bottom boundaries
            d[i][0] = d[i][1]*mod;
            d[i][N+1] = d[i][N]*mod;
        }

        // corners
        d[0][0] = (d[1][0] + d[0][1])/2;
        d[0][N+1] = (d[0][N] + d[1][N+1])/2;
        d[N+1][0] = (d[N][0] + d[N+1][1])/2;
        d[N+1][N+1] = (d[N][N+1] + d[N+1][N])/2;
    }

    void swap(float[][] a, float[][] b) {
        float[][] temp = a;
        a = b;
        b = temp;
    }
}
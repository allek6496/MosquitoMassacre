class Gas {
    int N;
    float dt;
    float viscosity;
    float diffusion;

    float[][] dens;
    float[][] velX;
    float[][] velY;



    void addSmoke(int x, int y, float amt) {
        dens[x][y] += amt;
    }

    void addForce(int x, int y, float fX, float fY) {
        velX[x][y] += fX;
        velY[x][y] += fY;
    }
}
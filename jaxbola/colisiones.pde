// ---------------- IMPULSO / FISICA ----------------
void aplicarImpulso(PVector vel, float ax, float ay) {
  if (ax != 0 || ay != 0) {
    PVector dir = new PVector(ax, ay);
    dir.normalize();
    vel.x += dir.x * velJugador * 0.35;
    vel.y += dir.y * velJugador * 0.35;
    float maxV = velJugador;
    if (vel.mag() > maxV) {
      vel.normalize();
      vel.mult(maxV);
    }
  }
}

void chocarJugadorJugador() {
  chocarCirculos(p1Pos, p1Vel, radioJugador, p2Pos, p2Vel, radioJugador);
}

void chocarJugadorPelota(PVector jPos, PVector jVel) {
  float dist = PVector.dist(jPos, ballPos);
  float minDist = radioJugador + radioBall;
  if (dist < minDist && dist > 0.001) {
    PVector normal = PVector.sub(ballPos, jPos);
    normal.normalize();

    float overlap = minDist - dist;
    ballPos.add(PVector.mult(normal, overlap));
    
    ballVel.x = normal.x + jVel.x * 0.99;
    ballVel.y = normal.y + jVel.y * 0.99;
  }
}

void chocarCirculos(PVector posA, PVector velA, float rA, PVector posB, PVector velB, float rB) {
  float dist = PVector.dist(posA, posB);
  float minDist = rA + rB;
  if (dist < minDist && dist > 0.001) {
    PVector normal = PVector.sub(posB, posA);
    normal.normalize();
    float overlap = (minDist - dist) / 2;

    posA.sub(PVector.mult(normal, overlap));
    posB.add(PVector.mult(normal, overlap));

    PVector relVel = PVector.sub(velB, velA);
    float velANormal = relVel.dot(normal);
    if (velANormal < 0) {
      PVector impulso = PVector.mult(normal, velANormal);
      velA.add(impulso);
      velB.sub(impulso);
    }
  }
}

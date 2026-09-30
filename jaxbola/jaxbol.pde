// ============================================================
//  HAXBALL TRUCHO - v2: con PATADA y MULTIJUGADOR EN RED (LAN)
// ------------------------------------------------------------
//  NOTA sobre la RED: usa broadcast UDP en la LAN para
//  encontrarse solos (igual que tu ejemplo). Si arrancás los
//  dos programas EXACTAMENTE al mismo tiempo puede que ninguno
//  encuentre al otro y los dos terminen de "servidor": arrancá
//  primero uno, esperá 2 segunditos, y después el otro.
//  Tiene que ser la misma red/WiFi y el firewall tiene que
//  dejar pasar a Processing/Java (aceptá el cartelito si sale).
// ============================================================

import processing.net.*;
import java.net.*;

// ---------------- ESTADO GENERAL ----------------
String pantalla = "MENU";   // MENU, BUSCANDO, JUEGO
String modo = "";           // LOCAL, RED

// ---- Cancha ----
float campoX, campoY, campoW, campoH;
float arcoAlto = 160;
float arcoAncho = 20;

// ---- Jugadores ----
PVector p1Pos, p1Vel;
PVector p2Pos, p2Vel;
float radioJugador = 22;
float velJugador = 3;
float friccionJugador = 0.85;

// ---- Pelota ----
PVector ballPos, ballVel;
float radioBall = 10;
float friccionBall = 0.975;

// ---- Patada ----
float radioPatada = radioJugador + radioBall + 10;
float fuerzaPatada = 8;
int cooldownPatada = 10;
int p1KickCD = 0;
int p2KickCD = 0;
ArrayList<float[]> efectosPatada = new ArrayList<float[]>();

// ---- Marcador ----
int scoreP1 = 0;
int scoreP2 = 0;
int golMostrarTimer = 0;
String golTexto = "";

void setup() {
  size(900, 600);
  campoW = width - 100;
  campoH = height - 100;
  campoX = (width - campoW) / 2;
  campoY = (height - campoH) / 2;

  reiniciarPosiciones();
}

void reiniciarPosiciones() {
  p1Pos = new PVector(campoX + campoW * 0.25, height / 2);
  p1Vel = new PVector(0, 0);

  p2Pos = new PVector(campoX + campoW * 0.75, height / 2);
  p2Vel = new PVector(0, 0);

  ballPos = new PVector(width / 2, height / 2);
  ballVel = new PVector(0, 0);

  p1KickCD = 0;
  p2KickCD = 0;
  efectosPatada.clear();
}

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

void actualizarPos(PVector pos, PVector vel, float friccion, float radio, boolean esJugador) {
  pos.add(vel);
  vel.mult(friccion);

  boolean enZonaArco = (pos.y > height/2 - arcoAlto/2 && pos.y < height/2 + arcoAlto/2);

  if (!esJugador && pos.y - radio < campoY) {
    pos.y = campoY + radio;
    vel.y *= -0.6;
  }
  if (!esJugador && pos.y + radio > campoY + campoH) {
    pos.y = campoY + campoH - radio;
    vel.y *= -0.6;
  }

  if (!esJugador && !enZonaArco) {
    if (pos.x - radio < campoX) {
      pos.x = campoX + radio;
      vel.x *= -0.6;
    }
    if (pos.x + radio > campoX + campoW) {
      pos.x = campoX + campoW - radio;
      vel.x *= -0.6;
    }
  } else {
    if (pos.x - radio < campoX - arcoAncho) {
      pos.x = campoX - arcoAncho + radio;
      vel.x *= -0.6;
    }
    if (pos.x + radio > campoX + campoW + arcoAncho) {
      pos.x = campoX + campoW + arcoAncho - radio;
      vel.x *= -0.6;
    }
  }
}

// ---------------- PATADA ----------------
// Si hay cooldown, lo va bajando. Si se apretó la tecla y la pelota
// está en rango, le pega fuerte y reinicia el cooldown.
int procesarPatada(PVector jPos, PVector jVel, boolean kickPresionado, int cd) {
  if (cd > 0) return cd - 1;
  if (kickPresionado) {
    float dist = PVector.dist(jPos, ballPos);
    if (dist < radioPatada) {
      PVector dir = PVector.sub(ballPos, jPos);
      if (dir.mag() < 0.001) dir = new PVector(1, 0);
      dir.normalize();
      ballVel.x = dir.x * fuerzaPatada + jVel.x * 0.3;
      ballVel.y = dir.y * fuerzaPatada + jVel.y * 0.3;
      agregarEfecto(jPos.x, jPos.y);
      return cooldownPatada;
    }
  }
  return 0;
}

void agregarEfecto(float x, float y) {
  efectosPatada.add(new float[]{x, y, 18});
}

void actualizarYDibujarEfectos() {
  noFill();
  strokeWeight(3);
  for (int i = efectosPatada.size() - 1; i >= 0; i--) {
    float[] e = efectosPatada.get(i);
    float vida = e[2];
    float alpha = map(vida, 0, 18, 0, 255);
    float tam = map(vida, 18, 0, radioJugador * 1.2, radioPatada * 1.6);
    stroke(255, 255, 0, alpha);
    ellipse(e[0], e[1], tam, tam);
    e[2] = vida - 1;
    if (e[2] <= 0) efectosPatada.remove(i);
  }
  noStroke();
}

// ---------------- GOLES ----------------
void chequearGol() {
  boolean enZonaArco = (ballPos.y > height/2 - arcoAlto/2 && ballPos.y < height/2 + arcoAlto/2);
  if (!enZonaArco) return;

  if (ballPos.x - radioBall < campoX - arcoAncho + 2) {
    scoreP2++;
    golTexto = "GOL DE P2!";
    golMostrarTimer = 90;
    reiniciarPosiciones();
  } else if (ballPos.x + radioBall > campoX + campoW + arcoAncho - 2) {
    scoreP1++;
    golTexto = "GOL DE P1!";
    golMostrarTimer = 90;
    reiniciarPosiciones();
  }
}

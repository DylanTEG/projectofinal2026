// ============================================================
//  ESTADO Y VARIABLES GLOBALES DEL JUEGO
// ============================================================
String pantalla = "MENU";
String modo = "";

float campoX, campoY, campoW, campoH;
float arcoAlto = 160;
float arcoAncho = 20;

// Instancias de POO
Jugador p1, p2;
Pelota pelota;
Palo[] palos = new Palo[4]; // 2 palos por arco

ArrayList<float[]> efectosPatada = new ArrayList<float[]>();

int scoreP1 = 0;
int scoreP2 = 0;
int golMostrarTimer = 0;
String golTexto = "";

// Variables para manejo de Red
Server s = null;
Client c = null;
boolean esServidor = false;
String serverIP = "";
boolean running = true;
int myID;
boolean rUp, rDown, rLeft, rRight, rKick;

// ---------------- SETUP & REINICIO ----------------
void setup() {
  size(900, 600);
  campoW = width - 100;
  campoH = height - 100;
  campoX = (width - campoW) / 2;
  campoY = (height - campoH) / 2;

  // Crear Objetos
  p1 = new Jugador(campoX + campoW * 0.25, height / 2, 22, 3, color(230, 60, 60), "P1");
  p2 = new Jugador(campoX + campoW * 0.75, height / 2, 22, 3, color(60, 120, 230), "P2");
  pelota = new Pelota(width / 2, height / 2, 8, 0.985, color(255));

  // Instanciar Palos (2 del arco izquierdo, 2 del arco derecho)
  float radioPalo = 8;
  palos[0] = new Palo(campoX, height/2 - arcoAlto/2, radioPalo);
  palos[1] = new Palo(campoX, height/2 + arcoAlto/2, radioPalo);
  palos[2] = new Palo(campoX + campoW, height/2 - arcoAlto/2, radioPalo);
  palos[3] = new Palo(campoX + campoW, height/2 + arcoAlto/2, radioPalo);

  reiniciarPosiciones();
}

void reiniciarPosiciones() {
  p1.pos.set(campoX + campoW * 0.25, height / 2);
  p1.vel.set(0, 0);

  p2.pos.set(campoX + campoW * 0.75, height / 2);
  p2.vel.set(0, 0);

  pelota.pos.set(width / 2, height / 2);
  pelota.vel.set(0, 0);

  efectosPatada.clear();
}

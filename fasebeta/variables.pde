// ============================================================
// ESTADO Y VARIABLES GLOBALES DEL JUEGO
// ============================================================
String pantalla = "MENU"; // "MENU" o "JUEGO"

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

// Temporizador de partido (4 minutos = 240 segundos = 14400 frames a 60 FPS)
int tiempoRestante = 14400;
boolean partidoFinalizado = false;
int finPartidoTimer = 0;
String textoGanador = "";

// Control de saque tras gol (1 = Saca P1/Rojo, 2 = Saca P2/Azul, 0 = Sin restriccion)
int equipoSaque = 0;

// Sonidos
SoundFile sndGol, sndPelota, sndPalo, sndInicio, sndFin;

// ---------------- SETUP & REINICIO ----------------
void setup() {
  size(900, 600);
  campoW = width - 100;
  campoH = height - 100;
  campoX = (width - campoW) / 2;
  campoY = (height - campoH) / 2;

  // Cargar archivos de sonido
  try {
    sndGol = new SoundFile(this, "gol.wav");
    sndPelota = new SoundFile(this, "pelota.wav");
    sndPalo = new SoundFile(this, "palo.wav");
    sndInicio = new SoundFile(this, "inicio.wav");
    sndFin = new SoundFile(this, "fin.wav");
  } catch (Exception e) {
    println("Cargue los archivos de sonido en la carpeta data/");
  }

  // Crear Objetos
  p1 = new Jugador(campoX + campoW * 0.25, height / 2, 22, 3, color(230, 60, 60), "P1");
  p2 = new Jugador(campoX + campoW * 0.75, height / 2, 22, 3, color(60, 120, 230), "P2");
  pelota = new Pelota(width / 2, height / 2, 8, 0.985, color(255));

  float radioPalo = 8;
  palos[0] = new Palo(campoX, height / 2 - arcoAlto / 2, radioPalo);
  palos[1] = new Palo(campoX, height / 2 + arcoAlto / 2, radioPalo);
  palos[2] = new Palo(campoX + campoW, height / 2 - arcoAlto / 2, radioPalo);
  palos[3] = new Palo(campoX + campoW, height / 2 + arcoAlto / 2, radioPalo);
}

// Reinicia marcador, tiempo y posiciones: se usa al empezar un partido nuevo
void reiniciarPartidoCompleto() {
  scoreP1 = 0;
  scoreP2 = 0;
  tiempoRestante = 14400; // 4 minutos a 60 FPS
  partidoFinalizado = false;
  finPartidoTimer = 0;
  textoGanador = "";
  equipoSaque = 0;
  reiniciarPosiciones();
  if (sndInicio != null) sndInicio.play();
}

// Reinicia solo las posiciones (se usa tras cada gol)
void reiniciarPosiciones() {
  p1.pos.set(campoX + campoW * 0.25, height / 2);
  p1.vel.set(0, 0);

  p2.pos.set(campoX + campoW * 0.75, height / 2);
  p2.vel.set(0, 0);

  pelota.pos.set(width / 2, height / 2);
  pelota.vel.set(0, 0);

  efectosPatada.clear();

  // Para que el sonido del palo pueda volver a sonar en el próximo contacto
  for (Palo p : palos) p.enContactoConPelota = false;
}

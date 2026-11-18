// ============================================================
// ESTADO Y VARIABLES GLOBALES DEL JUEGO
// ============================================================
String pantalla = "MENU";   // "MENU", "INGRESAR_IP", "BUSCANDO", "CONECTANDO", "ESPERANDO" o "JUEGO"
String modo = "";           // "LOCAL" o "RED"

float campoX, campoY, campoW, campoH;
float arcoAlto = 160;
float arcoAncho = 20;

// ---------------- JUGADORES (1 a 4) ----------------
// El slot define el equipo: pares (0 y 2) = ROJO, impares (1 y 3) = AZUL.
// Modo LOCAL: siempre se usan los slots 0 y 1 (mismo teclado, 2 jugadores).
// Modo RED: el slot 0 es el anfitrión (host) y los slots 1, 2 y 3 se asignan
// en orden a cada cliente que se conecta (hasta 4 jugadores en total).
final int MAX_JUGADORES = 4;
Jugador[] jugadores = new Jugador[MAX_JUGADORES];
boolean[] activo = new boolean[MAX_JUGADORES];
int numJugadores = 0; // jugadores activos en la partida/sala actual

// Último input recibido de cada slot (up,down,left,right,kick). Se usa en
// logicaServidorRed() (ver red.pde); se declara acá, después de MAX_JUGADORES,
// para que el orden de los campos sea válido al unir todas las pestañas.
int[][] inputRed = new int[MAX_JUGADORES][5];

Pelota pelota;
Palo[] palos = new Palo[4]; // 2 palos por arco

ArrayList<float[]> efectosPatada = new ArrayList<float[]>();

int scoreRojo = 0;
int scoreAzul = 0;
int golMostrarTimer = 0;
String golTexto = "";

// Temporizador de partido (4 minutos = 240 segundos = 14400 frames a 60 FPS)
int tiempoRestante = 14400;
boolean partidoFinalizado = false;
int finPartidoTimer = 0;
String textoGanador = "";

// Control de saque tras gol (1 = Saca ROJO, 2 = Saca AZUL, 0 = Sin restriccion)
int equipoSaque = 0;

// Sonidos
SoundFile sndGol, sndPelota, sndPalo, sndInicio, sndFin;

// ---------------- RED (modo online) ----------------
Server s = null;                                   // solo existe en el anfitrión (host)
Client c = null;                                    // solo existe en los clientes
Client[] clienteDeSlot = new Client[MAX_JUGADORES]; // qué conexión controla cada slot (el 0, del host, queda en null)
boolean esServidor = false;
String serverIP = "";
boolean running = true;
int miSlot = 0; // en modo RED, qué slot soy yo (lo informa el host al conectarme)

String ipTexto = "";   // lo que vas tecleando en la pantalla "Unirme por IP"
String mensajeRed = ""; // último error de red para mostrar en el menú ("no se encontró anfitrión", etc.)
String miIP = "";       // IP local del anfitrión, para mostrársela a los demás jugadores

// Bandera para avisarle a los clientes que la pelota tocó un palo este frame
// (el sonido en el host ya se reproduce dentro de Pelota.chocarCon)
boolean palotocadoEsteFrame = false;

// ---------------- SETUP ----------------
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

  crearJugadores();
  pelota = new Pelota(width / 2, height / 2, 8, 0.985, color(255));

  float radioPalo = 8;
  palos[0] = new Palo(campoX, height / 2 - arcoAlto / 2, radioPalo);
  palos[1] = new Palo(campoX, height / 2 + arcoAlto / 2, radioPalo);
  palos[2] = new Palo(campoX + campoW, height / 2 - arcoAlto / 2, radioPalo);
  palos[3] = new Palo(campoX + campoW, height / 2 + arcoAlto / 2, radioPalo);
}

// Crea los 4 jugadores posibles (existen siempre, pero solo se dibujan/mueven
// los que estén "activo[i] == true" según el modo elegido).
void crearJugadores() {
  for (int i = 0; i < MAX_JUGADORES; i++) {
    boolean esRojo = (i % 2 == 0); // slots pares = ROJO, impares = AZUL
    color col = esRojo ? color(230, 60, 60) : color(60, 120, 230);
    String etiqueta = (esRojo ? "R" : "A") + (i / 2 + 1); // R1, A1, R2, A2
    jugadores[i] = new Jugador(0, 0, 22, 3, col, etiqueta, esRojo);
    activo[i] = false;
  }
}

// Reinicia marcador, tiempo y posiciones: se usa al empezar (o reiniciar) un partido
void reiniciarPartidoCompleto() {
  scoreRojo = 0;
  scoreAzul = 0;
  tiempoRestante = 14400; // 4 minutos a 60 FPS
  partidoFinalizado = false;
  finPartidoTimer = 0;
  textoGanador = "";
  equipoSaque = 0;
  reiniciarPosiciones();
  if (sndInicio != null) sndInicio.play();
}

// Reinicia posiciones de todos los jugadores activos y de la pelota (tras cada gol)
void reiniciarPosiciones() {
  ubicarEquipo(slotsDelEquipo(true), campoX + campoW * 0.25);  // Rojo, lado izquierdo
  ubicarEquipo(slotsDelEquipo(false), campoX + campoW * 0.75); // Azul, lado derecho

  pelota.pos.set(width / 2, height / 2);
  pelota.vel.set(0, 0);

  efectosPatada.clear();
  for (Palo p : palos) p.enContactoConPelota = false;
}

// Devuelve, en orden, los slots activos que pertenecen a un equipo
int[] slotsDelEquipo(boolean rojo) {
  int[] tmp = new int[MAX_JUGADORES];
  int n = 0;
  for (int i = 0; i < MAX_JUGADORES; i++) {
    if (activo[i] && jugadores[i].esRojo == rojo) tmp[n++] = i;
  }
  return Arrays.copyOf(tmp, n);
}

// Ubica a los jugadores de un equipo en una misma columna X, repartidos en Y
// (si hay 1 jugador queda al centro, si hay 2 se separan arriba/abajo, etc.)
void ubicarEquipo(int[] slots, float x) {
  int n = slots.length;
  for (int k = 0; k < n; k++) {
    float offsetY = (k - (n - 1) / 2.0) * 80;
    Jugador j = jugadores[slots[k]];
    j.pos.set(x, height / 2 + offsetY);
    j.vel.set(0, 0);
  }
}

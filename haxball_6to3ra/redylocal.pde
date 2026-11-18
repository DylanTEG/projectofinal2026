// controles y lógica del modo LOCAL (2 jugadores, mismo teclado)

boolean[] keyPressedMap = new boolean[128];
boolean upPressed, downPressed, leftPressed, rightPressed, enterPressed;

// Combina WASD y flechas como si fueran el mismo control: lo usa cada jugador
// de una partida en RED, que tiene su propio teclado completo para él solo.
int[] leerInputCombinado() {
  int up    = (keyPressedMap['w'] || keyPressedMap['W'] || upPressed)    ? 1 : 0;
  int down  = (keyPressedMap['s'] || keyPressedMap['S'] || downPressed)  ? 1 : 0;
  int left  = (keyPressedMap['a'] || keyPressedMap['A'] || leftPressed)  ? 1 : 0;
  int right = (keyPressedMap['d'] || keyPressedMap['D'] || rightPressed) ? 1 : 0;
  int kick  = (keyPressedMap[' '] || keyPressedMap['x'] || keyPressedMap['X']) ? 1 : 0;
  return new int[]{up, down, left, right, kick};
}

void keyPressed() {
  if (pantalla.equals("MENU")) {
    if (key == 'L' || key == 'l') {
      modo = "LOCAL";
      activo[0] = true;
      activo[1] = true;
      activo[2] = false;
      activo[3] = false;
      numJugadores = 2;
      reiniciarPartidoCompleto();
      pantalla = "JUEGO";
    } else if (key == 'H' || key == 'h') {
      // Ser anfitrión: abre la partida de una vez, sin depender de ninguna búsqueda
      modo = "RED";
      serAnfitrion();
    } else if (key == 'J' || key == 'j') {
      // Unirse escribiendo la IP del anfitrión a mano (lo más confiable entre
      // computadoras distintas, porque no depende del broadcast UDP)
      modo = "RED";
      ipTexto = "";
      mensajeRed = "";
      pantalla = "INGRESAR_IP";
    } else if (key == 'B' || key == 'b') {
      // Buscar automáticamente en la red local (cómodo, pero depende de que
      // el firewall deje pasar el broadcast UDP entre las dos máquinas)
      modo = "RED";
      mensajeRed = "";
      pantalla = "BUSCANDO";
      thread("hiloBuscarAutomatico");
    }
    return;
  }

  if (pantalla.equals("INGRESAR_IP")) {
    if (keyCode == ENTER || keyCode == RETURN) {
      if (ipTexto.length() > 0) thread("hiloConectarManual");
    } else if (keyCode == BACKSPACE) {
      if (ipTexto.length() > 0) ipTexto = ipTexto.substring(0, ipTexto.length() - 1);
    } else if (keyCode == ESC) {
      key = 0; // evita que Processing cierre el sketch (ESC lo hace por defecto)
      pantalla = "MENU";
      modo = "";
    } else if ((key >= '0' && key <= '9') || key == '.') {
      if (ipTexto.length() < 15) ipTexto += key; // "15" alcanza para una IPv4 completa
    }
    return;
  }

  if (pantalla.equals("ESPERANDO")) {
    // Solo el anfitrión puede arrancar la partida, y solo con ENTER
    if (esServidor && (keyCode == ENTER || keyCode == RETURN)) {
      try { if (s != null) s.write("INICIO\n"); } catch (Exception e) {}
      reiniciarPartidoCompleto();
      pantalla = "JUEGO";
    }
    return;
  }

  if (pantalla.equals("BUSCANDO") || pantalla.equals("CONECTANDO")) return;

  // Pantalla JUEGO: registramos qué teclas están apretadas
  if (key >= 0 && key < 128) keyPressedMap[key] = true;
  if (keyCode == UP) upPressed = true;
  if (keyCode == DOWN) downPressed = true;
  if (keyCode == LEFT) leftPressed = true;
  if (keyCode == RIGHT) rightPressed = true;
  if (keyCode == ENTER || keyCode == RETURN) enterPressed = true;
}

void keyReleased() {
  if (!pantalla.equals("JUEGO")) return;
  if (key >= 0 && key < 128) keyPressedMap[key] = false;
  if (keyCode == UP) upPressed = false;
  if (keyCode == DOWN) downPressed = false;
  if (keyCode == LEFT) leftPressed = false;
  if (keyCode == RIGHT) rightPressed = false;
  if (keyCode == ENTER || keyCode == RETURN) enterPressed = false;
}

void exit() {
  running = false;
  try { if (s != null) s.stop(); } catch (Exception e) {}
  try { if (c != null) c.stop(); } catch (Exception e) {}
  super.exit();
}

// ---------------- LOGICA MODO LOCAL ----------------
// Siempre usa los slots 0 (Rojo, WASD + espacio/X) y 1 (Azul, flechas + ENTER).
void logicaLocal() {
  float ax1 = 0, ay1 = 0;
  if (keyPressedMap['w'] || keyPressedMap['W']) ay1 -= 1;
  if (keyPressedMap['s'] || keyPressedMap['S']) ay1 += 1;
  if (keyPressedMap['a'] || keyPressedMap['A']) ax1 -= 1;
  if (keyPressedMap['d'] || keyPressedMap['D']) ax1 += 1;
  jugadores[0].aplicarImpulso(ax1, ay1);

  float ax2 = 0, ay2 = 0;
  if (upPressed) ay2 -= 1;
  if (downPressed) ay2 += 1;
  if (leftPressed) ax2 -= 1;
  if (rightPressed) ax2 += 1;
  jugadores[1].aplicarImpulso(ax2, ay2);

  jugadores[0].actualizar();
  jugadores[1].actualizar();
  pelota.actualizar();

  // Paredes invisibles si hay saque pendiente
  if (equipoSaque != 0) {
    jugadores[0].aplicarParedInvisibleSaque(equipoSaque);
    jugadores[1].aplicarParedInvisibleSaque(equipoSaque);
    if (PVector.dist(pelota.pos, new PVector(width / 2, height / 2)) > 15) {
      equipoSaque = 0;
    }
  }

  jugadores[0].rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  jugadores[1].rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  pelota.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, false);

  // Colisiones POO
  jugadores[0].chocarCon(jugadores[1]);
  pelota.chocarCon(jugadores[0]);
  pelota.chocarCon(jugadores[1]);
  for (Palo palo : palos) {
    pelota.chocarCon(palo);
    jugadores[0].chocarCon(palo);
    jugadores[1].chocarCon(palo);
  }

  // Patadas (el sonido se dispara adentro de intentarPatear, una sola vez por patada)
  if (keyPressedMap[' '] || keyPressedMap['x'] || keyPressedMap['X']) jugadores[0].intentarPatear(pelota, efectosPatada);
  if (enterPressed) jugadores[1].intentarPatear(pelota, efectosPatada);

  chequearGol();
}

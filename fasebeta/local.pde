// controles, colisiones, actualizaciones, patada (modo local, 2 jugadores, mismo teclado)

boolean[] keyPressedMap = new boolean[128];
boolean upPressed, downPressed, leftPressed, rightPressed, enterPressed;

void keyPressed() {
  if (pantalla.equals("MENU")) {
    if (key == 'L' || key == 'l' || keyCode == ENTER || keyCode == RETURN) {
      reiniciarPartidoCompleto();
      pantalla = "JUEGO";
    }
    return;
  }
  if (key >= 0 && key < 128) keyPressedMap[key] = true;
  if (keyCode == UP) upPressed = true;
  if (keyCode == DOWN) downPressed = true;
  if (keyCode == LEFT) leftPressed = true;
  if (keyCode == RIGHT) rightPressed = true;
  if (keyCode == ENTER || keyCode == RETURN) enterPressed = true;
}

void keyReleased() {
  if (pantalla.equals("MENU")) return;
  if (key >= 0 && key < 128) keyPressedMap[key] = false;
  if (keyCode == UP) upPressed = false;
  if (keyCode == DOWN) downPressed = false;
  if (keyCode == LEFT) leftPressed = false;
  if (keyCode == RIGHT) rightPressed = false;
  if (keyCode == ENTER || keyCode == RETURN) enterPressed = false;
}

// ---------------- LOGICA DEL PARTIDO (LOCAL) ----------------
void logicaLocal() {
  // Controles P1 (WASD + ESPACIO/X para patear)
  float ax1 = 0, ay1 = 0;
  if (keyPressedMap['w'] || keyPressedMap['W']) ay1 -= 1;
  if (keyPressedMap['s'] || keyPressedMap['S']) ay1 += 1;
  if (keyPressedMap['a'] || keyPressedMap['A']) ax1 -= 1;
  if (keyPressedMap['d'] || keyPressedMap['D']) ax1 += 1;
  p1.aplicarImpulso(ax1, ay1);

  // Controles P2 (flechas + ENTER para patear)
  float ax2 = 0, ay2 = 0;
  if (upPressed) ay2 -= 1;
  if (downPressed) ay2 += 1;
  if (leftPressed) ax2 -= 1;
  if (rightPressed) ax2 += 1;
  p2.aplicarImpulso(ax2, ay2);

  // Actualizaciones de posición
  p1.actualizar();
  p2.actualizar();
  pelota.actualizar();

  // Aplicar paredes invisibles si hay saque pendiente
  if (equipoSaque != 0) {
    p1.aplicarParedInvisibleSaque(true, equipoSaque);
    p2.aplicarParedInvisibleSaque(false, equipoSaque);

    // Si la pelota se mueve fuera del centro, finaliza la restricción de saque
    if (PVector.dist(pelota.pos, new PVector(width / 2, height / 2)) > 15) {
      equipoSaque = 0;
    }
  }

  p1.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  p2.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  pelota.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, false);

  // Colisiones POO
  p1.chocarCon(p2);
  pelota.chocarCon(p1);
  pelota.chocarCon(p2);
  for (Palo palo : palos) {
    pelota.chocarCon(palo);
    p1.chocarCon(palo);
    p2.chocarCon(palo);
  }

  // Patadas (el sonido se dispara adentro de intentarPatear, una sola vez por patada)
  if (keyPressedMap[' '] || keyPressedMap['x'] || keyPressedMap['X']) p1.intentarPatear(pelota, efectosPatada);
  if (enterPressed) p2.intentarPatear(pelota, efectosPatada);

  chequearGol();
}

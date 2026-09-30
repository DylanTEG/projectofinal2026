// lee movimiento combinando WASD + flechas (para el modo RED, un solo jugador por compu)
int[] leerInputCombinado() {
  int up    = (keyPressedMap['w'] || keyPressedMap['W'] || upPressed)    ? 1 : 0;
  int down  = (keyPressedMap['s'] || keyPressedMap['S'] || downPressed)  ? 1 : 0;
  int left  = (keyPressedMap['a'] || keyPressedMap['A'] || leftPressed)  ? 1 : 0;
  int right = (keyPressedMap['d'] || keyPressedMap['D'] || rightPressed) ? 1 : 0;
  int kick  = keyPressedMap[' '] ? 1 : 0;
  return new int[]{up, down, left, right, kick};
}

// ---------------- MANEJO DE TECLAS ----------------
boolean[] keyPressedMap = new boolean[128];
boolean upPressed, downPressed, leftPressed, rightPressed, enterPressed;

void keyPressed() {
  if (pantalla.equals("MENU")) {
    if (key == 'L' || key == 'l') {
      modo = "LOCAL";
      reiniciarPosiciones();
      pantalla = "JUEGO";
    } else if (key == 'N' || key == 'n') {
      modo = "RED";
      pantalla = "BUSCANDO";
      thread("iniciarRed");
    }
    return;
  }

  if (key >= 0 && key < 128) keyPressedMap[key] = true;
  if (keyCode == UP) upPressed = true;
  if (keyCode == DOWN) downPressed = true;
  if (keyCode == LEFT) leftPressed = true;
  if (keyCode == RIGHT) rightPressed = true;
  if (keyCode == ENTER || keyCode == RETURN) enterPressed = true;

  if (modo.equals("LOCAL") && (key == 'r' || key == 'R')) {
    reiniciarPosiciones();
  }
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

void exit() {
  running = false;
  try {
    if (s != null) s.stop();
  }
  catch (Exception e) {}
  try {
    if (c != null) c.stop();
  }
  catch (Exception e) {}
  super.exit();
}

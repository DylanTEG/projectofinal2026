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

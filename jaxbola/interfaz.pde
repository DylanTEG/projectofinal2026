// ---------------- DIBUJO ----------------
void dibujarMenu() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(36);
  text("HAXBALL TRUCHO", width / 2, height / 2 - 90);
  textSize(20);
  text("Presioná L para modo LOCAL (2 jugadores, mismo teclado)", width / 2, height / 2 - 10);
  text("Presioná N para modo RED (LAN, cada uno en su compu)", width / 2, height / 2 + 20);
  textSize(14);
  text("Local: P1 = WASD + ESPACIO patea   |   P2 = Flechas + ENTER patea", width / 2, height / 2 + 60);
  text("Red: movete con WASD o flechas, ESPACIO para patear", width / 2, height / 2 + 85);
}

void dibujarBuscando() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("Buscando partida en la red local...", width / 2, height / 2 - 20);
  textSize(14);
  text("(si no encuentra a nadie en 1.5s, esta compu pasa a ser el servidor)", width / 2, height / 2 + 20);
}

// ---------------- BUCLE PRINCIPAL ----------------
void draw() {
  if (pantalla.equals("MENU")) {
    dibujarMenu();
    return;
  }
  if (pantalla.equals("BUSCANDO")) {
    dibujarBuscando();
    return;
  }

  background(30, 120, 40);
  dibujarCancha();

  if (modo.equals("LOCAL")) {
    logicaLocal();
  } else if (modo.equals("RED")) {
    if (esServidor) logicaServidorRed();
    else logicaClienteRed();
  }

  // Dibujar objetos
  p1.dibujar();
  p2.dibujar();
  pelota.dibujar();
  for (Palo p : palos) {
    p.dibujar();
  }

  actualizarYDibujarEfectos();
  dibujarMarcador();

  if (golMostrarTimer > 0) {
    golMostrarTimer--;
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(48);
    text(golTexto, width / 2, height / 2 - 100);
  }
}

// ---------------- DIBUJO CANCHA Y MENUS ----------------
void dibujarCancha() {
  noStroke();
  for (int i = 0; i < 12; i++) {
    fill(i % 2 == 0 ? color(30, 130, 45) : color(28, 118, 40));
    rect(i * width / 12.0, 0, width / 12.0, height);
  }

  stroke(255);
  strokeWeight(4);
  noFill();
  rect(campoX, campoY, campoW, campoH);
  line(width/2, campoY, width/2, campoY + campoH);
  
  noStroke();
  fill(255);
  ellipse(width/2, height/2, 90, 90);
  fill(30, 130, 45);
  ellipse(width/2, height/2, 84, 84);

  // Redes
  stroke(255, 220, 0);
  strokeWeight(6);
  line(campoX - arcoAncho, height/2 - arcoAlto/2, campoX, height/2 - arcoAlto/2);
  line(campoX - arcoAncho, height/2 + arcoAlto/2, campoX, height/2 + arcoAlto/2);
  line(campoX - arcoAncho, height/2 - arcoAlto/2, campoX - arcoAncho, height/2 + arcoAlto/2);
  line(campoX + campoW, height/2 - arcoAlto/2, campoX + campoW + arcoAncho, height/2 - arcoAlto/2);
  line(campoX + campoW, height/2 + arcoAlto/2, campoX + campoW + arcoAncho, height/2 + arcoAlto/2);
  line(campoX + campoW + arcoAncho, height/2 - arcoAlto/2, campoX + campoW + arcoAncho, height/2 + arcoAlto/2);
  noStroke();
}

void dibujarMarcador() {
  fill(0, 150);
  rect(width/2 - 110, 10, 220, 50, 10);
  fill(230, 60, 60);
  textAlign(CENTER, CENTER);
  textSize(26);
  text(scoreP1, width/2 - 60, 35);
  fill(255);
  textSize(20);
  text("-", width/2, 35);
  fill(60, 120, 230);
  textSize(26);
  text(scoreP2, width/2 + 60, 35);
}

void chequearGol() {
  boolean enZonaArco = (pelota.pos.y > height/2 - arcoAlto/2 && pelota.pos.y < height/2 + arcoAlto/2);
  if (!enZonaArco) return;

  if (pelota.pos.x - pelota.radio < campoX - arcoAncho + 2) {
    scoreP2++;
    golTexto = "GOL DE P2!";
    golMostrarTimer = 90;
    reiniciarPosiciones();
  } else if (pelota.pos.x + pelota.radio > campoX + campoW + arcoAncho - 2) {
    scoreP1++;
    golTexto = "GOL DE P1!";
    golMostrarTimer = 90;
    reiniciarPosiciones();
  }
}

void actualizarYDibujarEfectos() {
  noFill();
  strokeWeight(3);
  for (int i = efectosPatada.size() - 1; i >= 0; i--) {
    float[] e = efectosPatada.get(i);
    float vida = e[2];
    float alpha = map(vida, 0, 18, 0, 255);
    float tam = map(vida, 18, 0, 22 * 1.2, 42 * 1.6);
    stroke(255, 255, 0, alpha);
    ellipse(e[0], e[1], tam, tam);
    e[2] = vida - 1;
    if (e[2] <= 0) efectosPatada.remove(i);
  }
  noStroke();
}

void dibujarMenu() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(36);
  text("HAXBALL POO", width / 2, height / 2 - 90);
  textSize(20);
  text("Presioná L para modo LOCAL (2 jugadores, mismo teclado)", width / 2, height / 2 - 10);
  text("Presioná N para modo RED (LAN, cada uno en su compu)", width / 2, height / 2 + 20);
}

void dibujarBuscando() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("Buscando partida en la red local...", width / 2, height / 2 - 20);
}

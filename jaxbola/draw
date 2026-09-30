// ================================================================
//  DRAW
// ================================================================
void draw() {
  if (pantalla.equals("MENU")) {
    dibujarMenu();
    return;
  }
  if (pantalla.equals("BUSCANDO")) {
    dibujarBuscando();
    return;
  }

  // ---- JUEGO ----
  background(30, 120, 40);
  dibujarCancha();

  if (modo.equals("LOCAL")) {
    logicaLocal();
  } else if (modo.equals("RED")) {
    if (esServidor) logicaServidorRed();
    else logicaClienteRed();
  }

  dibujarJugador(p1Pos, color(230, 60, 60), "P1");
  dibujarJugador(p2Pos, color(60, 120, 230), "P2");
  dibujarPelota();
  actualizarYDibujarEfectos();
  dibujarMarcador();

  if (modo.equals("RED")) {
    fill(255);
    textAlign(LEFT, TOP);
    textSize(14);
    text(esServidor ? "Sos el SERVIDOR (P1 - rojo)" : "Sos el CLIENTE (P2 - azul)", 10, 10);
  }

  if (golMostrarTimer > 0) {
    golMostrarTimer--;
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(48);
    text(golTexto, width / 2, height / 2 - 100);
  }
}

void dibujarCancha() {
  noStroke();
  for (int i = 0; i < 12; i++) {
    if (i % 2 == 0) fill(30, 130, 45);
    else fill(28, 118, 40);
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

void dibujarJugador(PVector pos, color col, String etiqueta) {
  stroke(0, 80);
  strokeWeight(2);
  fill(col);
  ellipse(pos.x, pos.y, radioJugador * 2, radioJugador * 2);
  noStroke();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(14);
  text(etiqueta, pos.x, pos.y);
}

void dibujarPelota() {
  stroke(0);
  strokeWeight(2);
  fill(255);
  ellipse(ballPos.x, ballPos.y, radioBall * 2, radioBall * 2);
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

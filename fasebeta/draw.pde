// ---------------- BUCLE PRINCIPAL ----------------
void draw() {
  if (pantalla.equals("MENU")) {
    dibujarMenu();
    return;
  }

  background(30, 120, 40);
  dibujarCancha();

  // Mientras el partido sigue en curso, se actualiza la física y el reloj
  if (!partidoFinalizado) {
    logicaLocal();

    // Descuenta tiempo si no está pausado por gol
    if (golMostrarTimer == 0 && tiempoRestante > 0) {
      tiempoRestante--;
      if (tiempoRestante <= 0) {
        finalizarPartido();
      }
    }
  }

  // Dibujar objetos (se siguen mostrando también en la pantalla de fin de partido)
  p1.dibujar();
  p2.dibujar();
  pelota.dibujar();
  for (Palo p : palos) {
    p.dibujar();
  }

  actualizarYDibujarEfectos();
  dibujarMarcador();

  // Cartel de Gol
  if (golMostrarTimer > 0) {
    golMostrarTimer--;
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(48);
    text(golTexto, width / 2, height / 2 - 100);
  }

  // Cartel de Fin de Partido (5 segundos = 300 frames), fuera del "if (!partidoFinalizado)"
  // de arriba para que se siga dibujando y la cuenta regresiva avance hasta volver al menú
  if (partidoFinalizado) {
    fill(0, 200);
    rect(0, 0, width, height);
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(42);
    text(textoGanador, width / 2, height / 2);

    finPartidoTimer--;
    if (finPartidoTimer <= 0) {
      pantalla = "MENU";
    }
  }
}

void finalizarPartido() {
  partidoFinalizado = true;
  finPartidoTimer = 300; // 5 segundos
  if (scoreP1 > scoreP2) {
    textoGanador = "¡Ganó el equipo Rojo!";
  } else if (scoreP2 > scoreP1) {
    textoGanador = "¡Ganó el equipo Azul!";
  } else {
    textoGanador = "¡Empate!";
  }
  if (sndFin != null) sndFin.play();
}

void dibujarMarcador() {
  fill(0, 150);
  rect(width / 2 - 160, 10, 320, 50, 10);
  fill(230, 60, 60);
  textAlign(CENTER, CENTER);
  textSize(24);
  text(scoreP1, width / 2 - 100, 35);

  fill(255);
  textSize(18);
  int min = tiempoRestante / 3600;
  int seg = (tiempoRestante / 60) % 60;
  String reloj = nf(min, 2) + ":" + nf(seg, 2);
  text(reloj, width / 2, 35);

  fill(60, 120, 230);
  textSize(24);
  text(scoreP2, width / 2 + 100, 35);
}

void chequearGol() {
  boolean enZonaArco = (pelota.pos.y > height / 2 - arcoAlto / 2 && pelota.pos.y < height / 2 + arcoAlto / 2);
  if (!enZonaArco) return;

  if (pelota.pos.x - pelota.radio < campoX - arcoAncho + 2) {
    scoreP2++;
    golTexto = "GOL DE P2!";
    golMostrarTimer = 90;
    equipoSaque = 1; // Gol de P2 -> Saca P1 (Rojo)
    if (sndGol != null) sndGol.play();
    reiniciarPosiciones();
  } else if (pelota.pos.x + pelota.radio > campoX + campoW + arcoAncho - 2) {
    scoreP1++;
    golTexto = "GOL DE P1!";
    golMostrarTimer = 90;
    equipoSaque = 2; // Gol de P1 -> Saca P2 (Azul)
    if (sndGol != null) sndGol.play();
    reiniciarPosiciones();
  }
}

// ---------------- DIBUJO CANCHA Y MENU ----------------
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
  line(width / 2, campoY, width / 2, campoY + campoH);

  noStroke();
  fill(255);
  ellipse(width / 2, height / 2, 90, 90);
  fill(30, 130, 45);
  ellipse(width / 2, height / 2, 84, 84);

  // Redes
  stroke(255, 220, 0);
  strokeWeight(6);
  line(campoX - arcoAncho, height / 2 - arcoAlto / 2, campoX, height / 2 - arcoAlto / 2);
  line(campoX - arcoAncho, height / 2 + arcoAlto / 2, campoX, height / 2 + arcoAlto / 2);
  line(campoX - arcoAncho, height / 2 - arcoAlto / 2, campoX - arcoAncho, height / 2 + arcoAlto / 2);
  line(campoX + campoW, height / 2 - arcoAlto / 2, campoX + campoW + arcoAncho, height / 2 - arcoAlto / 2);
  line(campoX + campoW, height / 2 + arcoAlto / 2, campoX + campoW + arcoAncho, height / 2 + arcoAlto / 2);
  line(campoX + campoW + arcoAncho, height / 2 - arcoAlto / 2, campoX + campoW + arcoAncho, height / 2 + arcoAlto / 2);
  noStroke();
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
  text("HAXBALL POO", width / 2, height / 2 - 110);
  textSize(20);
  text("Presioná ENTER o L para jugar (2 jugadores, mismo teclado)", width / 2, height / 2 - 40);
  textSize(16);
  text("P1 (Rojo): W A S D para moverse, ESPACIO o X para patear", width / 2, height / 2);
  text("P2 (Azul): Flechas para moverse, ENTER para patear", width / 2, height / 2 + 25);
}

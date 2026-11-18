// ---------------- BUCLE PRINCIPAL ----------------
void draw() {
  // Si soy cliente de una partida en red, reviso los mensajes del anfitrión en
  // TODO momento (aunque todavía estemos en la sala de espera), no solo durante
  // el juego. Así nos enteramos de nuestro slot, de que el anfitrión arrancó la
  // partida, o de que la sala está llena.
  if (modo.equals("RED") && !esServidor) leerRedCliente();

  if (pantalla.equals("MENU")) {
    dibujarMenu();
    return;
  }
  if (pantalla.equals("INGRESAR_IP")) {
    dibujarIngresarIP();
    return;
  }
  if (pantalla.equals("BUSCANDO")) {
    dibujarBuscando();
    return;
  }
  if (pantalla.equals("CONECTANDO")) {
    dibujarConectando();
    return;
  }
  if (pantalla.equals("ESPERANDO")) {
    dibujarEsperando();
    return;
  }

  background(30, 120, 40);
  dibujarCancha();

  // Mientras el partido sigue en curso se actualiza la física y, en modo LOCAL,
  // el reloj (en modo RED el reloj lo maneja el anfitrión y llega sincronizado).
  if (!partidoFinalizado) {
    if (modo.equals("LOCAL")) {
      logicaLocal();
      if (golMostrarTimer == 0 && tiempoRestante > 0) {
        tiempoRestante--;
        if (tiempoRestante <= 0) {
          finalizarPartido();
        }
      }
    } else if (modo.equals("RED") && esServidor) {
      logicaServidorRed(); // acá adentro también se actualiza el reloj
    }
    // Si soy cliente en modo RED no hago nada más: la posición de todos los
    // jugadores y de la pelota ya se actualizó en leerRedCliente() (arriba).
  }

  // Dibujar objetos
  for (int i = 0; i < MAX_JUGADORES; i++) {
    if (activo[i]) jugadores[i].dibujar();
  }
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

  // Cartel de Fin de Partido (5 segundos = 300 frames). Queda fuera del
  // "if (!partidoFinalizado)" de arriba para que se siga dibujando y la cuenta
  // regresiva avance hasta volver al menú (o a la sala de espera, en modo RED).
  if (partidoFinalizado) {
    fill(0, 200);
    rect(0, 0, width, height);
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(42);
    text(textoGanador, width / 2, height / 2);

    finPartidoTimer--;
    if (finPartidoTimer <= 0) {
      pantalla = modo.equals("RED") ? "ESPERANDO" : "MENU";
    }
  }
}

void finalizarPartido() {
  partidoFinalizado = true;
  finPartidoTimer = 300; // 5 segundos
  if (scoreRojo > scoreAzul) {
    textoGanador = "¡Ganó el equipo Rojo!";
  } else if (scoreAzul > scoreRojo) {
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
  text(scoreRojo, width / 2 - 100, 35);

  fill(255);
  textSize(18);
  int min = tiempoRestante / 3600;
  int seg = (tiempoRestante / 60) % 60;
  String reloj = nf(min, 2) + ":" + nf(seg, 2);
  text(reloj, width / 2, 35);

  fill(60, 120, 230);
  textSize(24);
  text(scoreAzul, width / 2 + 100, 35);
}

// Chequea si la pelota entró en un arco. Lo llama tanto logicaLocal() como
// logicaServidorRed() (en modo RED solo corre en el anfitrión, que es quien
// decide el resultado y se lo manda a los clientes).
void chequearGol() {
  boolean enZonaArco = (pelota.pos.y > height / 2 - arcoAlto / 2 && pelota.pos.y < height / 2 + arcoAlto / 2);
  if (!enZonaArco) return;

  if (pelota.pos.x - pelota.radio < campoX - arcoAncho + 2) {
    scoreAzul++;
    golTexto = "¡GOL DEL EQUIPO AZUL!";
    golMostrarTimer = 90;
    equipoSaque = 1; // Gol del Azul -> Saca el Rojo
    if (sndGol != null) sndGol.play();
    reiniciarPosiciones();
  } else if (pelota.pos.x + pelota.radio > campoX + campoW + arcoAncho - 2) {
    scoreRojo++;
    golTexto = "¡GOL DEL EQUIPO ROJO!";
    golMostrarTimer = 90;
    equipoSaque = 2; // Gol del Rojo -> Saca el Azul
    if (sndGol != null) sndGol.play();
    reiniciarPosiciones();
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
  text("HAXBALL POO", width / 2, height / 2 - 150);
  textSize(20);
  text("Presioná L para modo LOCAL (2 jugadores, mismo teclado)", width / 2, height / 2 - 80);

  textSize(16);
  text("Modo RED (2 a 4 jugadores en la misma red local):", width / 2, height / 2 - 40);
  textSize(18);
  text("H = Ser anfitrión", width / 2, height / 2 - 10);
  text("J = Unirme por IP (recomendado entre computadoras distintas)", width / 2, height / 2 + 15);
  text("B = Buscar automáticamente en la red", width / 2, height / 2 + 40);

  textSize(14);
  text("Moverse: WASD o flechas  |  Patear: ESPACIO, X o ENTER", width / 2, height / 2 + 80);

  if (mensajeRed.length() > 0) {
    fill(255, 140, 140);
    textSize(15);
    text(mensajeRed, width / 2, height / 2 + 115);
  }
}

// Pantalla para tipear la IP del anfitrión a mano (modo "Unirme por IP")
void dibujarIngresarIP() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(22);
  text("Escribí la IP de la computadora anfitriona:", width / 2, height / 2 - 60);

  fill(0);
  rect(width / 2 - 140, height / 2 - 20, 280, 40, 6);
  fill(255);
  textSize(20);
  text(ipTexto.length() > 0 ? ipTexto : "_", width / 2, height / 2);

  textSize(14);
  text("ENTER para conectar   |   ESC para volver", width / 2, height / 2 + 40);
}

void dibujarConectando() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(22);
  text("Conectando a " + ipTexto + "...", width / 2, height / 2);
}

void dibujarBuscando() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("Buscando un anfitrión en la red local...", width / 2, height / 2);
}

// Sala de espera del modo RED: muestra cuántos jugadores hay conectados y, si
// sos el anfitrión, te deja arrancar la partida cuando quieras.
void dibujarEsperando() {
  background(20, 90, 30);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(28);
  if (esServidor) {
    text("Sos el anfitrión. Jugadores conectados: " + numJugadores + " / " + MAX_JUGADORES, width / 2, height / 2 - 50);
    textSize(18);
    text("Tu IP (pasásela a los demás para que se unan con J): " + miIP, width / 2, height / 2 - 15);
    text("Presioná ENTER para iniciar la partida", width / 2, height / 2 + 20);
  } else {
    text("Conectado. Esperando a que el anfitrión inicie la partida...", width / 2, height / 2);
    textSize(16);
    text("Tu jugador es: " + (jugadores[miSlot] != null ? jugadores[miSlot].etiqueta : "?"), width / 2, height / 2 + 40);
  }
}

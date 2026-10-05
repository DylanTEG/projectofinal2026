// red, controles, colisiones, actualizaciones, patada

// ---------------- LOGICA MODO LOCAL ----------------
void logicaLocal() {
  // Controles P1
  float ax1 = 0, ay1 = 0;
  if (keyPressedMap['w'] || keyPressedMap['W']) ay1 -= 1;
  if (keyPressedMap['s'] || keyPressedMap['S']) ay1 += 1;
  if (keyPressedMap['a'] || keyPressedMap['A']) ax1 -= 1;
  if (keyPressedMap['d'] || keyPressedMap['D']) ax1 += 1;
  p1.aplicarImpulso(ax1, ay1);

  // Controles P2
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

  // Patadas
  if (keyPressedMap[' ']) p1.intentarPatear(pelota, efectosPatada);
  if (enterPressed) p2.intentarPatear(pelota, efectosPatada);

  chequearGol();
}

// ---------------- LOGICA MODO RED ----------------
void logicaServidorRed() {
  if (s != null) {
    try {
      Client remitente = s.available();
      if (remitente != null) {
        String input = remitente.readStringUntil('\n');
        if (input != null) {
          input = trim(input);
          String[] partes = split(input, ' ');
          if (partes.length == 6 && partes[0].equals("I")) {
            rUp    = int(partes[1]) == 1;
            rDown  = int(partes[2]) == 1;
            rLeft  = int(partes[3]) == 1;
            rRight = int(partes[4]) == 1;
            rKick  = int(partes[5]) == 1;
          }
        }
      }
    } catch (Exception e) {}
  }

  int[] inLocal = leerInputCombinado();
  float ax1 = 0, ay1 = 0;
  if (inLocal[0] == 1) ay1 -= 1;
  if (inLocal[1] == 1) ay1 += 1;
  if (inLocal[2] == 1) ax1 -= 1;
  if (inLocal[3] == 1) ax1 += 1;
  p1.aplicarImpulso(ax1, ay1);

  float ax2 = 0, ay2 = 0;
  if (rUp) ay2 -= 1;
  if (rDown) ay2 += 1;
  if (rLeft) ax2 -= 1;
  if (rRight) ax2 += 1;
  p2.aplicarImpulso(ax2, ay2);

  p1.actualizar();
  p2.actualizar();
  pelota.actualizar();

  p1.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  p2.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  pelota.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, false);

  p1.chocarCon(p2);
  pelota.chocarCon(p1);
  pelota.chocarCon(p2);

  for (Palo palo : palos) {
    pelota.chocarCon(palo);
    p1.chocarCon(palo);
    p2.chocarCon(palo);
  }

  boolean k1 = inLocal[4] == 1 && p1.intentarPatear(pelota, efectosPatada);
  boolean k2 = rKick && p2.intentarPatear(pelota, efectosPatada);

  chequearGol();
  int golFlag = (golMostrarTimer == 90) ? ((golTexto.indexOf("P1") != -1) ? 1 : 2) : 0;

  if (s != null) {
    String estado = "S " + p1.pos.x + " " + p1.pos.y + " " + p2.pos.x + " " + p2.pos.y + " "
      + pelota.pos.x + " " + pelota.pos.y + " " + scoreP1 + " " + scoreP2 + " "
      + (k1 ? 1 : 0) + " " + (k2 ? 1 : 0) + " " + golFlag + "\n";
    try { s.write(estado); } catch (Exception e) {}
  }
}

void logicaClienteRed() {
  int[] inLocal = leerInputCombinado();
  if (c != null) {
    try {
      c.write("I " + inLocal[0] + " " + inLocal[1] + " " + inLocal[2] + " " + inLocal[3] + " " + inLocal[4] + "\n");
    } catch (Exception e) {}
  }

  if (c != null) {
    try {
      while (c.available() > 0) {
        String input = c.readStringUntil('\n');
        if (input == null) break;
        input = trim(input);
        String[] p = split(input, ' ');
        if (p.length == 12 && p[0].equals("S")) {
          p1.pos.x = float(p[1]);
          p1.pos.y = float(p[2]);
          p2.pos.x = float(p[3]);
          p2.pos.y = float(p[4]);
          pelota.pos.x = float(p[5]);
          pelota.pos.y = float(p[6]);
          scoreP1 = int(p[7]);
          scoreP2 = int(p[8]);
          if (int(p[9]) == 1) efectosPatada.add(new float[]{p1.pos.x, p1.pos.y, 18});
          if (int(p[10]) == 1) efectosPatada.add(new float[]{p2.pos.x, p2.pos.y, 18});
          int golFlag = int(p[11]);
          if (golFlag == 1) { golTexto = "GOL DE P1!"; golMostrarTimer = 90; }
          else if (golFlag == 2) { golTexto = "GOL DE P2!"; golMostrarTimer = 90; }
        }
      }
    } catch (Exception e) {}
  }
}

void iniciarRed() {
  serverIP = buscarServidorEnRed();
  if (serverIP != null) {
    esServidor = false;
    myID = (int) random(1, 1000000);
    c = new Client(this, serverIP, 12345);
  } else {
    esServidor = true;
    myID = 0;
    s = new Server(this, 12345);
    thread("responderDescubrimiento");
  }
  reiniciarPosiciones();
  pantalla = "JUEGO";
}

String buscarServidorEnRed() {
  try {
    DatagramSocket socket = new DatagramSocket();
    socket.setBroadcast(true);
    byte[] mensaje = "HAY_SERVER?".getBytes();
    DatagramPacket paqueteEnvio = new DatagramPacket(mensaje, mensaje.length, InetAddress.getByName("255.255.255.255"), 8888);
    socket.send(paqueteEnvio);
    socket.setSoTimeout(1500);
    byte[] bufferRecepcion = new byte[1024];
    DatagramPacket paqueteRespuesta = new DatagramPacket(bufferRecepcion, bufferRecepcion.length);
    socket.receive(paqueteRespuesta);
    String ipDescubierta = paqueteRespuesta.getAddress().getHostAddress();
    socket.close();
    return ipDescubierta;
  } catch (Exception e) { return null; }
}

void responderDescubrimiento() {
  try {
    DatagramSocket serverSocket = new DatagramSocket(8888);
    byte[] bufferRecepcion = new byte[1024];
    while (running) {
      DatagramPacket paqueteEntrante = new DatagramPacket(bufferRecepcion, bufferRecepcion.length);
      serverSocket.receive(paqueteEntrante);
      String mensaje = new String(paqueteEntrante.getData(), 0, paqueteEntrante.getLength());
      if (mensaje.equals("HAY_SERVER?")) {
        byte[] respuesta = "ESTOY".getBytes();
        DatagramPacket paqueteRespuesta = new DatagramPacket(respuesta, respuesta.length, paqueteEntrante.getAddress(), paqueteEntrante.getPort());
        serverSocket.send(paqueteRespuesta);
      }
    }
  } catch (Exception e) {}
}

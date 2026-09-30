// ---------------- RED ----------------
Server s = null;
Client c = null;
boolean esServidor = false;
String serverIP = "";
boolean running = true;
int myID;

// input remoto recibido (usado por el servidor para mover al P2)
boolean rUp, rDown, rLeft, rRight, rKick;

// ================================================================
//  LOGICA MODO LOCAL (2 jugadores, mismo teclado)
// ================================================================
void logicaLocal() {
  // P1: WASD + espacio
  float ax1 = 0, ay1 = 0;
  if (keyPressedMap['w'] || keyPressedMap['W']) ay1 -= 1;
  if (keyPressedMap['s'] || keyPressedMap['S']) ay1 += 1;
  if (keyPressedMap['a'] || keyPressedMap['A']) ax1 -= 1;
  if (keyPressedMap['d'] || keyPressedMap['D']) ax1 += 1;
  aplicarImpulso(p1Vel, ax1, ay1);
  boolean kick1 = keyPressedMap[' '];

  // P2: flechas + enter
  float ax2 = 0, ay2 = 0;
  if (upPressed) ay2 -= 1;
  if (downPressed) ay2 += 1;
  if (leftPressed) ax2 -= 1;
  if (rightPressed) ax2 += 1;
  aplicarImpulso(p2Vel, ax2, ay2);
  boolean kick2 = enterPressed;

  actualizarPos(p1Pos, p1Vel, friccionJugador, radioJugador, true);
  actualizarPos(p2Pos, p2Vel, friccionJugador, radioJugador, true);
  actualizarPos(ballPos, ballVel, friccionBall, radioBall, false);

  chocarJugadorJugador();
  chocarJugadorPelota(p1Pos, p1Vel);
  chocarJugadorPelota(p2Pos, p2Vel);

  p1KickCD = procesarPatada(p1Pos, p1Vel, kick1, p1KickCD);
  p2KickCD = procesarPatada(p2Pos, p2Vel, kick2, p2KickCD);

  chequearGol();
}

// ================================================================
//  LOGICA MODO RED - SERVIDOR (simula todo, manda el estado)
// ================================================================
void logicaServidorRed() {
  // leer input que mandó el cliente
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
    }
    catch (Exception e) { /* trucho: ignoramos errores de socket */ }
  }

  // P1 = jugador local del servidor
  int[] inLocal = leerInputCombinado();
  float ax1 = 0, ay1 = 0;
  if (inLocal[0] == 1) ay1 -= 1;
  if (inLocal[1] == 1) ay1 += 1;
  if (inLocal[2] == 1) ax1 -= 1;
  if (inLocal[3] == 1) ax1 += 1;
  aplicarImpulso(p1Vel, ax1, ay1);
  boolean kick1 = inLocal[4] == 1;

  // P2 = jugador remoto (cliente)
  float ax2 = 0, ay2 = 0;
  if (rUp) ay2 -= 1;
  if (rDown) ay2 += 1;
  if (rLeft) ax2 -= 1;
  if (rRight) ax2 += 1;
  aplicarImpulso(p2Vel, ax2, ay2);
  boolean kick2 = rKick;

  actualizarPos(p1Pos, p1Vel, friccionJugador, radioJugador, true);
  actualizarPos(p2Pos, p2Vel, friccionJugador, radioJugador, true);
  actualizarPos(ballPos, ballVel, friccionBall, radioBall, false);

  chocarJugadorJugador();
  chocarJugadorPelota(p1Pos, p1Vel);
  chocarJugadorPelota(p2Pos, p2Vel);

  p1KickCD = procesarPatada(p1Pos, p1Vel, kick1, p1KickCD);
  boolean seKick1 = (p1KickCD == cooldownPatada);
  p2KickCD = procesarPatada(p2Pos, p2Vel, kick2, p2KickCD);
  boolean seKick2 = (p2KickCD == cooldownPatada);

  chequearGol();
  int golFlag = 0;
  if (golMostrarTimer == 90) {
    golFlag = (golTexto.indexOf("P1") != -1) ? 1 : 2;
  }

  // mandar estado completo al cliente
  if (s != null) {
    String estado = "S " + p1Pos.x + " " + p1Pos.y + " " + p2Pos.x + " " + p2Pos.y + " "
      + ballPos.x + " " + ballPos.y + " " + scoreP1 + " " + scoreP2 + " "
      + (seKick1 ? 1 : 0) + " " + (seKick2 ? 1 : 0) + " " + golFlag + "\n";
    try {
      s.write(estado);
    }
    catch (Exception e) { /* trucho */ }
  }
}

// ================================================================
//  LOGICA MODO RED - CLIENTE (solo manda input y dibuja lo que llega)
// ================================================================
void logicaClienteRed() {
  int[] inLocal = leerInputCombinado();
  if (c != null) {
    try {
      String msg = "I " + inLocal[0] + " " + inLocal[1] + " " + inLocal[2] + " " + inLocal[3] + " " + inLocal[4] + "\n";
      c.write(msg);
    }
    catch (Exception e) { /* trucho */ }
  }

  if (c != null) {
    try {
      while (c.available() > 0) {
        String input = c.readStringUntil('\n');
        if (input == null) break;
        input = trim(input);
        String[] p = split(input, ' ');
        if (p.length == 12 && p[0].equals("S")) {
          p1Pos.x = float(p[1]);
          p1Pos.y = float(p[2]);
          p2Pos.x = float(p[3]);
          p2Pos.y = float(p[4]);
          ballPos.x = float(p[5]);
          ballPos.y = float(p[6]);
          scoreP1 = int(p[7]);
          scoreP2 = int(p[8]);
          if (int(p[9]) == 1) agregarEfecto(p1Pos.x, p1Pos.y);
          if (int(p[10]) == 1) agregarEfecto(p2Pos.x, p2Pos.y);
          int golFlag = int(p[11]);
          if (golFlag == 1) {
            golTexto = "GOL DE P1!";
            golMostrarTimer = 90;
          } else if (golFlag == 2) {
            golTexto = "GOL DE P2!";
            golMostrarTimer = 90;
          }
        }
      }
    }
    catch (Exception e) { /* trucho */ }
  }
}

// ================================================================
//  RED: DESCUBRIMIENTO AUTOMATICO (UDP broadcast) - igual idea que
//  el ejemplo: gritamos "HAY_SERVER?" y si alguien contesta, nos
//  conectamos a esa IP. Si nadie contesta, nos convertimos en server.
// ================================================================
void iniciarRed() {
  serverIP = buscarServidorEnRed();

  if (serverIP != null) {
    esServidor = false;
    myID = (int) random(1, 1000000);
    c = new Client(this, serverIP, 12345);
    println("Modo: CLIENTE (ID " + myID + "). Conectado a " + serverIP);
  } else {
    esServidor = true;
    myID = 0;
    s = new Server(this, 12345);
    println("Modo: SERVIDOR. Esperando conexión...");
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
  }
  catch (Exception e) {
    return null;
  }
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
  }
  catch (Exception e) {
    println("Servidor de descubrimiento UDP cerrado.");
  }
}

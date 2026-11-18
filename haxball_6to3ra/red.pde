// ============================================================
//  MODO RED (ONLINE) - 2 a 4 jugadores en la misma red local (LAN)
// ============================================================
//
// Idea general: UN solo equipo (el "anfitrión"/host) simula TODA la física
// del partido (igual que en modo local). Los demás equipos ("clientes") solo
// mandan qué teclas tienen apretadas y dibujan en pantalla la posición que
// les llega del anfitrión. Así no hay que sincronizar física entre varias
// computadoras (que es complicado), solo números de posición.
//
// Para conectarse hay DOS caminos, a elección del jugador:
//   - "Unirme por IP" (tecla J): el cliente escribe a mano la IP del
//     anfitrión y se conecta directo por TCP (puerto 12345). Es el más
//     confiable entre computadoras distintas: solo depende de ese único
//     puerto, no de que el broadcast de la red deje pasar paquetes.
//   - "Buscar automáticamente" (tecla B): manda un "¿hay servidor?" por UDP
//     (puerto 8888) a toda la red local y usa quien le responda. Es más
//     cómodo (no hay que tipear nada) pero depende de que el broadcast UDP
//     llegue entre las dos máquinas, cosa que muchos firewalls bloquean.
//
// IMPORTANTE sobre firewalls: si entre dos ventanas de la MISMA computadora
// el modo red funciona pero entre DOS computadoras distintas no, casi
// siempre es el firewall de Windows (u otro) bloqueando el puerto 12345
// (TCP) y/o el 8888 (UDP) en una de las dos máquinas. Hay que permitirle a
// Java/Processing el acceso a redes "privadas" (y si la red figura como
// "pública", también ahí) la primera vez que el sistema lo pregunte, o
// agregar una regla de entrada manual para esos dos puertos.

// ---------------- ANFITRIÓN: ABRIR LA PARTIDA ----------------
// Se llama al presionar "H" en el menú. No depende de ninguna búsqueda:
// simplemente abre el puerto 12345 y espera a que se conecten.
void serAnfitrion() {
  try {
    s = new Server(this, 12345);
    esServidor = true;
    activo[0] = true;
    numJugadores = 1;
    miIP = obtenerIpLocal();
    mensajeRed = "";
    thread("responderDescubrimiento"); // para que la búsqueda automática (B) también te encuentre
    pantalla = "ESPERANDO";
  } catch (Exception e) {
    mensajeRed = "No se pudo abrir el servidor (¿el puerto 12345 está ocupado o bloqueado?).";
    pantalla = "MENU";
  }
}

// ---------------- CLIENTE: UNIRSE ESCRIBIENDO LA IP A MANO ----------------
// Envoltorio sin argumentos porque thread() de Processing solo puede llamar
// funciones sin parámetros; la IP tecleada ya está guardada en "ipTexto".
void hiloConectarManual() {
  intentarConectar(ipTexto);
}

// ---------------- CLIENTE: BÚSQUEDA AUTOMÁTICA EN LA LAN ----------------
void hiloBuscarAutomatico() {
  String ip = buscarServidorEnRed();
  if (ip != null) {
    intentarConectar(ip);
  } else {
    mensajeRed = "No se encontró ningún anfitrión en la red. Probá 'Unirse por IP' (J) escribiéndola a mano.";
    pantalla = "MENU";
  }
}

// Intenta conectarse por TCP a una IP concreta. Corre siempre en un hilo
// aparte (ver hiloConectarManual/hiloBuscarAutomatico) porque el intento de
// conexión puede tardar varios segundos si la IP está mal o el firewall del
// otro lado bloquea el puerto, y no queremos congelar el juego mientras tanto.
void intentarConectar(String ip) {
  pantalla = "CONECTANDO";
  try {
    Client intento = new Client(this, ip, 12345);
    int esperas = 0;
    while (!intento.active() && esperas < 40) { // espera hasta ~2 segundos
      delay(50);
      esperas++;
    }
    if (intento.active()) {
      c = intento;
      esServidor = false;
      serverIP = ip;
      mensajeRed = "";
      pantalla = "ESPERANDO";
    } else {
      intento.stop();
      mensajeRed = "No se pudo conectar a " + ip + ". Revisá la IP y que el firewall deje pasar el puerto 12345.";
      pantalla = "MENU";
    }
  } catch (Exception e) {
    mensajeRed = "No se pudo conectar a " + ip + ". Revisá la IP y que el firewall deje pasar el puerto 12345.";
    pantalla = "MENU";
  }
}

// Devuelve una IP local "de verdad" (de la red Wi-Fi o Ethernet), ignorando
// loopback (127.0.0.1) e interfaces virtuales, para mostrarle al anfitrión
// cuál es su propia dirección y pasársela a los demás jugadores.
String obtenerIpLocal() {
  try {
    Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
    while (interfaces.hasMoreElements()) {
      NetworkInterface iface = interfaces.nextElement();
      if (!iface.isUp() || iface.isLoopback() || iface.isVirtual()) continue;
      Enumeration<InetAddress> direcciones = iface.getInetAddresses();
      while (direcciones.hasMoreElements()) {
        InetAddress dir = direcciones.nextElement();
        if (dir instanceof Inet4Address && !dir.isLoopbackAddress()) {
          return dir.getHostAddress();
        }
      }
    }
  } catch (Exception e) {}
  return "(no se pudo detectar)";
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
  } catch (Exception e) {
    return null; // nadie contestó a tiempo
  }
}

// Corre solo en el anfitrión: contesta "ESTOY" a quien pregunte "HAY_SERVER?"
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

// ---------------- ANFITRIÓN: NUEVAS CONEXIONES ----------------
// Processing llama a esta función automáticamente cada vez que un cliente
// nuevo se conecta al Server "s". Le asignamos el primer lugar libre (slot 1, 2 o 3).
void serverEvent(Server server, Client client) {
  for (int i = 1; i < MAX_JUGADORES; i++) {
    if (clienteDeSlot[i] == null) {
      clienteDeSlot[i] = client;
      activo[i] = true;
      numJugadores++;
      client.write("SLOT " + i + "\n");
      reiniciarPosiciones(); // reacomoda a los equipos con el jugador nuevo
      return;
    }
  }
  // Ya hay 4 jugadores: no entra nadie más
  client.write("LLENO\n");
  client.stop();
}

// ---------------- ANFITRIÓN: LÓGICA DEL PARTIDO ----------------
// Corre una vez por frame, igual que logicaLocal(), pero moviendo hasta
// 4 jugadores en vez de 2, y al final le manda el resultado a cada cliente.
// (inputRed se declara en variables.pde, junto a MAX_JUGADORES)

void logicaServidorRed() {
  // 1) Recibir el input que mandó cada cliente conectado
  for (int i = 1; i < MAX_JUGADORES; i++) {
    Client cl = clienteDeSlot[i];
    if (cl == null) continue;
    try {
      while (cl.available() > 0) {
        String linea = cl.readStringUntil('\n');
        if (linea == null) break;
        linea = trim(linea);
        String[] partes = split(linea, ' ');
        if (partes.length == 6 && partes[0].equals("I")) {
          for (int k = 0; k < 5; k++) inputRed[i][k] = int(partes[k + 1]);
        }
      }
    } catch (Exception e) {}
  }

  // 2) Mi propio input (el anfitrión también juega, en el slot 0)
  int[] inHost = leerInputCombinado();
  for (int k = 0; k < 5; k++) inputRed[0][k] = inHost[k];

  // 3) Mover a todos los jugadores activos según su último input
  for (int i = 0; i < MAX_JUGADORES; i++) {
    if (!activo[i]) continue;
    float ax = 0, ay = 0;
    if (inputRed[i][0] == 1) ay -= 1;
    if (inputRed[i][1] == 1) ay += 1;
    if (inputRed[i][2] == 1) ax -= 1;
    if (inputRed[i][3] == 1) ax += 1;
    jugadores[i].aplicarImpulso(ax, ay);
    jugadores[i].actualizar();
  }
  pelota.actualizar();

  // Paredes invisibles si hay saque pendiente
  if (equipoSaque != 0) {
    for (int i = 0; i < MAX_JUGADORES; i++) {
      if (activo[i]) jugadores[i].aplicarParedInvisibleSaque(equipoSaque);
    }
    if (PVector.dist(pelota.pos, new PVector(width / 2, height / 2)) > 15) {
      equipoSaque = 0;
    }
  }

  for (int i = 0; i < MAX_JUGADORES; i++) {
    if (activo[i]) jugadores[i].rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, true);
  }
  pelota.rebotarParedes(campoX, campoY, campoW, campoH, arcoAlto, arcoAncho, false);

  // Colisiones: pelota contra cada jugador, jugadores entre sí, y todos contra los palos
  for (int i = 0; i < MAX_JUGADORES; i++) {
    if (!activo[i]) continue;
    pelota.chocarCon(jugadores[i]);
    for (int j = i + 1; j < MAX_JUGADORES; j++) {
      if (activo[j]) jugadores[i].chocarCon(jugadores[j]);
    }
    for (Palo palo : palos) jugadores[i].chocarCon(palo);
  }
  for (Palo palo : palos) pelota.chocarCon(palo);

  // Patadas: guardamos quién pateó este frame para avisarle a los clientes
  // (sonido + efecto visual) además de aplicarles la física acá mismo.
  boolean[] pateoEsteFrame = new boolean[MAX_JUGADORES];
  for (int i = 0; i < MAX_JUGADORES; i++) {
    if (activo[i] && inputRed[i][4] == 1) {
      pateoEsteFrame[i] = jugadores[i].intentarPatear(pelota, efectosPatada);
    }
  }

  chequearGol();

  // Reloj del partido (solo lo maneja el anfitrión; se sincroniza por red)
  int finFlag = 0;
  if (golMostrarTimer == 0 && tiempoRestante > 0) {
    tiempoRestante--;
    if (tiempoRestante <= 0) {
      finalizarPartido();
      finFlag = 1;
    }
  }

  int golFlag = 0;
  if (golMostrarTimer == 90) { // recién se acaba de marcar el gol este frame
    golFlag = golTexto.indexOf("AZUL") != -1 ? 2 : 1;
  }

  boolean paloFlag = palotocadoEsteFrame;
  palotocadoEsteFrame = false; // se consume en este mismo frame

  // 4) Armar y mandar el estado completo a todos los clientes conectados
  StringBuilder estado = new StringBuilder("S ");
  estado.append(scoreRojo).append(' ').append(scoreAzul).append(' ').append(tiempoRestante).append(' ');
  estado.append(golFlag).append(' ').append(finFlag).append(' ').append(paloFlag ? 1 : 0).append(' ');
  for (int i = 0; i < MAX_JUGADORES; i++) {
    estado.append(activo[i] ? 1 : 0).append(' ');
    estado.append(jugadores[i].pos.x).append(' ').append(jugadores[i].pos.y).append(' ');
    estado.append(pateoEsteFrame[i] ? 1 : 0).append(' ');
  }
  estado.append(pelota.pos.x).append(' ').append(pelota.pos.y).append('\n');

  if (s != null) {
    try { s.write(estado.toString()); } catch (Exception e) {}
  }
}

// ---------------- CLIENTE: ENVÍO DE INPUT Y RECEPCIÓN DEL ESTADO ----------------
// Se llama en todos los frames (incluso en la sala de espera) para no perderse
// mensajes como "SLOT", "INICIO" o "LLENO".
void leerRedCliente() {
  if (c == null) return;

  // Mandamos nuestras teclas solo mientras el partido está en curso
  if (pantalla.equals("JUEGO")) {
    int[] in = leerInputCombinado();
    try {
      c.write("I " + in[0] + " " + in[1] + " " + in[2] + " " + in[3] + " " + in[4] + "\n");
    } catch (Exception e) {}
  }

  try {
    while (c.available() > 0) {
      String linea = c.readStringUntil('\n');
      if (linea == null) break;
      linea = trim(linea);
      if (linea.length() == 0) continue;
      String[] p = split(linea, ' ');

      if (p[0].equals("SLOT")) {
        miSlot = int(p[1]);
      } else if (p[0].equals("LLENO")) {
        pantalla = "MENU";
        modo = "";
        mensajeRed = "La sala ya tiene 4 jugadores.";
      } else if (p[0].equals("INICIO")) {
        reiniciarPartidoCompleto();
        pantalla = "JUEGO";
      } else if (p[0].equals("S")) {
        int idx = 1;
        scoreRojo = int(p[idx++]);
        scoreAzul = int(p[idx++]);
        tiempoRestante = int(p[idx++]);
        int golFlag = int(p[idx++]);
        int finFlag = int(p[idx++]);
        int paloFlag = int(p[idx++]);

        for (int i = 0; i < MAX_JUGADORES; i++) {
          boolean act = int(p[idx++]) == 1;
          float x = float(p[idx++]);
          float y = float(p[idx++]);
          boolean pateo = int(p[idx++]) == 1;
          activo[i] = act;
          if (act) {
            jugadores[i].pos.set(x, y);
            if (pateo) {
              efectosPatada.add(new float[]{x, y, 18});
              if (sndPelota != null) sndPelota.play();
            }
          }
        }
        pelota.pos.set(float(p[idx++]), float(p[idx++]));

        if (golFlag == 1) {
          golTexto = "¡GOL DEL EQUIPO ROJO!";
          golMostrarTimer = 90;
          if (sndGol != null) sndGol.play();
        } else if (golFlag == 2) {
          golTexto = "¡GOL DEL EQUIPO AZUL!";
          golMostrarTimer = 90;
          if (sndGol != null) sndGol.play();
        }

        if (paloFlag == 1 && sndPalo != null) sndPalo.play();

        if (finFlag == 1 && !partidoFinalizado) finalizarPartido();
      }
    }
  } catch (Exception e) {}
}

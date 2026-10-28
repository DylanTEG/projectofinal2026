// ============================================================
//  HAXBALL POO - CLASES Y OBJETOS
// ============================================================

// ---------------- 1. CLASE BASE: PELOTA ----------------
class Pelota {
  PVector pos, vel;
  float radio;
  float friccion;
  color col;

  Pelota(float x, float y, float radio, float friccion, color col) {
    this.pos = new PVector(x, y);
    this.vel = new PVector(0, 0);
    this.radio = radio;
    this.friccion = friccion;
    this.col = col;
  }

  // Actualiza la posición aplicando física y fricción
  void actualizar() {
    pos.add(vel);
    vel.mult(friccion);
  }

  // Dibuja la pelota genérica
  void dibujar() {
    stroke(0);
    strokeWeight(2);
    fill(col);
    ellipse(pos.x, pos.y, radio * 2, radio * 2);
    noStroke();
  }

  // Resuelve el choque de este objeto contra otro (pelota-jugador, jugador-jugador o contra un palo).
  // El sonido del palo se maneja acá, una sola vez por contacto (ver "enContactoConPelota").
  // El sonido de la patada NO se maneja acá: se dispara en Jugador.intentarPatear().
  void chocarCon(Pelota otra) {
    float dist = PVector.dist(this.pos, otra.pos);
    float minDist = this.radio + otra.radio;

    if (otra instanceof Palo) {
      Palo palo = (Palo) otra;
      boolean tocando = dist < minDist && dist > 0.001;

      if (tocando) {
        PVector normal = PVector.sub(otra.pos, this.pos);
        normal.normalize();
        float overlap = minDist - dist;
        this.pos.sub(PVector.mult(normal, overlap));

        PVector relVel = PVector.sub(this.vel, otra.vel);
        float velNormal = relVel.dot(normal);
        if (velNormal > 0) {
          PVector impulso = PVector.mult(normal, velNormal * 1.5);
          this.vel.sub(impulso);
        }
      }

      // Sonido del palo: solo cuando la PELOTA entra en contacto (flanco de subida),
      // no en cada frame que siguen superpuestos ni cuando lo toca un jugador.
      if (this == pelota) {
        if (tocando && !palo.enContactoConPelota) {
          if (sndPalo != null) sndPalo.play();
          palo.enContactoConPelota = true;
        } else if (!tocando) {
          palo.enContactoConPelota = false;
        }
      }
      return;
    }

    // Choque genérico: pelota-jugador o jugador-jugador (sin sonido; el de la pelota
    // se reproduce únicamente al patear, ver Jugador.intentarPatear)
    if (dist < minDist && dist > 0.001) {
      PVector normal = PVector.sub(otra.pos, this.pos);
      normal.normalize();
      float overlap = (minDist - dist) / 2;
      this.pos.sub(PVector.mult(normal, overlap));
      otra.pos.add(PVector.mult(normal, overlap));

      PVector relVel = PVector.sub(otra.vel, this.vel);
      float velANormal = relVel.dot(normal);
      if (velANormal < 0) {
        PVector impulso = PVector.mult(normal, velANormal);
        this.vel.add(impulso);
        otra.vel.sub(impulso);
      }
    }
  }

  // Rebotar contra bordes de la cancha
  void rebotarParedes(float cX, float cY, float cW, float cH, float aAlto, float aAncho, boolean esJugador) {
    boolean enZonaArco = (pos.y > height / 2 - aAlto / 2 && pos.y < height / 2 + aAlto / 2);

    // Techo y piso del campo: aplica a todos los objetos (antes solo aplicaba a la pelota,
    // lo que permitía a los jugadores salirse de la pantalla)
    if (pos.y - radio < cY) {
      pos.y = cY + radio;
      vel.y *= -0.6;
    }
    if (pos.y + radio > cY + cH) {
      pos.y = cY + cH - radio;
      vel.y *= -0.6;
    }

    if (!esJugador && !enZonaArco) {
      if (pos.x - radio < cX) {
        pos.x = cX + radio;
        vel.x *= -0.6;
      }
      if (pos.x + radio > cX + cW) {
        pos.x = cX + cW - radio;
        vel.x *= -0.6;
      }
    } else {
      if (pos.x - radio < cX - aAncho) {
        pos.x = cX - aAncho + radio;
        vel.x *= -0.6;
      }
      if (pos.x + radio > cX + cW + aAncho) {
        pos.x = cX + cW + aAncho - radio;
        vel.x *= -0.6;
      }
    }
  }
}

// ---------------- 2. SUBCLASE: PALO (Palo de arco) ----------------
// Hereda de Pelota pero es estático (velocidad cero y fija)
class Palo extends Pelota {
  boolean enContactoConPelota = false; // para que el sonido suene una sola vez por contacto

  Palo(float x, float y, float radio) {
    super(x, y, radio, 1.0, color(255, 255, 255)); // Palos blancos por defecto
  }

  @Override
  void actualizar() {
    // Override vacío: los palos no se mueven ni acumulan velocidad
    vel.set(0, 0);
  }

  @Override
  void dibujar() {
    stroke(0);
    strokeWeight(2);
    fill(255, 220, 0); // Color postes
    ellipse(pos.x, pos.y, radio * 2, radio * 2);
    noStroke();
  }
}

// ---------------- 3. SUBCLASE: JUGADOR ----------------
class Jugador extends Pelota {
  String etiqueta;
  float velMax;
  float radioPatada;
  float fuerzaPatada;
  int cooldownPatada;
  int cdActual;

  Jugador(float x, float y, float radio, float velMax, color col, String etiqueta) {
    super(x, y, radio, 0.85, col);
    this.velMax = velMax;
    this.etiqueta = etiqueta;
    this.radioPatada = radio + 10 + 5; // Rango de alcance de patada
    this.fuerzaPatada = 7;
    this.cooldownPatada = 10;
    this.cdActual = 0;
  }

  void aplicarImpulso(float ax, float ay) {
    if (ax != 0 || ay != 0) {
      PVector dir = new PVector(ax, ay);
      dir.normalize();
      vel.x += dir.x * velMax * 0.35;
      vel.y += dir.y * velMax * 0.35;
      if (vel.mag() > velMax) {
        vel.normalize();
        vel.mult(velMax);
      }
    }
  }

  // Intenta patear la pelota. Devuelve true solo en el frame exacto en que patea
  // (gracias al cooldown), y es el único lugar donde suena el sonido de patada.
  boolean intentarPatear(Pelota pelota, ArrayList<float[]> efectos) {
    if (cdActual > 0) {
      cdActual--;
      return false;
    }

    float dist = PVector.dist(this.pos, pelota.pos);
    if (dist < radioPatada) {
      PVector dir = PVector.sub(pelota.pos, this.pos);
      if (dir.mag() < 0.001) dir = new PVector(1, 0);
      dir.normalize();
      pelota.vel.x = dir.x * fuerzaPatada + this.vel.x * 0.4;
      pelota.vel.y = dir.y * fuerzaPatada + this.vel.y * 0.4;

      efectos.add(new float[]{this.pos.x, this.pos.y, 18});
      cdActual = cooldownPatada;
      if (sndPelota != null) sndPelota.play();
      return true;
    }
    return false;
  }

  void aplicarParedInvisibleSaque(boolean esRojo, int equipoSaque) {
    float limiteMitad;
    // Si sacan los Azules (2), el Rojo (1) no puede cruzar a la derecha de la mitad
    if (esRojo && equipoSaque == 2) {
      limiteMitad = width / 2.1;
      if (pos.x + radio > limiteMitad) {
        pos.x = limiteMitad - radio;
        vel.x = 0;
      }
    }
    // Si sacan los Rojos (1), el Azul (2) no puede cruzar a la izquierda de la mitad
    if (!esRojo && equipoSaque == 1) {
      limiteMitad = width / 1.9;
      if (pos.x - radio < limiteMitad) {
        pos.x = limiteMitad + radio;
        vel.x = 0;
      }
    }
  }

  @Override
  void dibujar() {
    stroke(0, 80);
    strokeWeight(2);
    fill(col);
    ellipse(pos.x, pos.y, radio * 2, radio * 2);
    noStroke();
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(etiqueta, pos.x, pos.y);
  }
}

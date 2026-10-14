# Cambios

Versión y build de cada IPA (`version.json`). Los builds intermedios de prueba se compilaron en ramas
aparte y no se listan.

## 0.5.2 (build 23)

- **Import JSON from Files** (menú Randomizer, junto a Spoiler File, y Network → Anchor): carga el spoiler
  del randomizer que comparte el host para Anchor, o una configuración compartida, igual que soltar el
  archivo en la ventana en escritorio.
- Con un mando conectado, los botones A, B y C del juego vuelven a su posición, tamaño y opacidad
  originales aunque los controles táctiles dinámicos estén activos (antes quedaban en el layout táctil).

## 0.5.1 (build 22)

- Con los controles táctiles dinámicos, al sacar la ocarina se muestran los botones táctiles normales,
  porque el juego oculta A y C mientras se toca.
- La flecha abajo del d-pad táctil queda simétrica en el layout por defecto del iPhone.

## 0.5.0 (build 20)

- Los controles táctiles actúan directo sobre el control del jugador 1, con mapeo fijo, en vez de
  escribir teclas: el teclado queda libre y los bindings no los alteran.
- Stick táctil análogo, con una zona muerta pequeña.
- **Touch Camera Stick** (Settings → Controls, apagado por defecto): un segundo stick que actúa como el
  stick derecho, para Free Look. Editable en Customize Touch Layout.
- **Touch Haptics** (encendido por defecto): vibración suave al presionar un botón táctil.

## 0.4.1 (build 19)

- Con una pantalla externa conectada, el menú abierto en el dispositivo ya no hace saltar los FPS a la tasa
  del dispositivo: el juego mantiene la tasa de la pantalla externa, y Native Screen Resolution no aplica.
- El audio se vuelve a abrir solo cuando iOS cambia la salida (tele, audífonos, AirPods). Antes podía
  quedar en silencio al conectar o desconectar en caliente.

## 0.4.0 (build 18)

- **Extend to External Display** (Settings → Graphics, activado por defecto): el juego pasa a pantalla
  completa en la tele o el monitor (USB-C/HDMI o AirPlay), a su resolución real de salida, y el dispositivo
  queda como control. El menú abierto con `•••` aparece en el dispositivo; abierto desde un control, en la
  pantalla externa.
- Los controles táctiles se ocultan solos con un gamepad conectado (el botón de menú se mantiene).
- Los FPS siguen la tasa de la pantalla donde está el juego.
- Corregido el texto del menú que se corrompía al cambiar de pantalla.
- CI: verificación de que los parches de SDL se apliquen sobre código limpio y ya parchado.

## 0.3.1 (build 12)

- En iPadOS 26+, el control (DualSense, Xbox) ya no escribe teclas fantasma (flechas, Return, Escape,
  Pause), y ○/B ya no abre el menú.

## 0.3.0 (build 10)

- Actualizado a **Ship of Harkinian 9.3.0 "Dewey"**, con el upstream oficial fijado por commit y parches
  revisables. La extracción de la ROM usa **Torch**, el extractor oficial de 9.3.0.
- Menú **Network** habilitado: Anchor, Sail y Crowd Control (SDL2_net estático para iOS).
- ProMotion: la interpolación sigue la tasa real de la pantalla (120 Hz, o 60 en modo de bajo consumo).
- Menús nítidos a la resolución del panel y opción **Native Screen Resolution** para el juego.
- **Lock at 60 FPS**, opcional, para jugar a resolución nativa con 60 estables.
- Scroll táctil en los menús, sin mover sliders por accidente.
- Nuevo bundle ID `cl.mtbolanoss.harkinianpad` y README en español.

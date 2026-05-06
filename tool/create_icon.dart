// Corre con: dart run tool/create_icon.dart
// Genera assets/icon.png, assets/icon_fg.png y assets/splash_logo.png

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Generando iconos...');
  Directory('assets').createSync(recursive: true);

  _createFullIcon();
  _createForegroundIcon();
  _createSplashLogo();

  print('');
  print('✓ assets/icon.png       (ícono principal)');
  print('✓ assets/icon_fg.png    (foreground para adaptive icon)');
  print('✓ assets/splash_logo.png (logo del splash screen)');
  print('');
  print('Siguiente paso:');
  print('  flutter pub get');
  print('  dart run flutter_launcher_icons');
  print('  dart run flutter_native_splash:create');
}

// ── Ícono principal 1024x1024 ──────────────────────────────────
void _createFullIcon() {
  final image = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Fondo azul circular
  _circle(image, 512, 512, 510, _blue);

  // Cuerpo de la billetera (blanco)
  _roundRect(image, 185, 310, 839, 730, 55, _white);

  // Solapa superior (azul oscuro)
  _roundRect(image, 185, 310, 839, 450, 55, _darkBlue);
  // Tapa la curva inferior de la solapa para que sea recta
  _rect(image, 185, 400, 839, 450, _darkBlue);

  // Franja de tarjeta
  _rect(image, 185, 510, 839, 555, img.ColorRgba8(200, 220, 255, 255));

  // Moneda (anillos concéntricos)
  _circle(image, 660, 630, 95, _darkBlue);
  _circle(image, 660, 630, 82, _white);
  _circle(image, 660, 630, 60, _darkBlue);

  // Símbolo $ en la moneda (barra vertical + 2 horizontales)
  _rect(image, 654, 580, 666, 680, _white);
  _rect(image, 636, 598, 684, 612, _white);
  _rect(image, 636, 648, 684, 662, _white);

  File('assets/icon.png').writeAsBytesSync(img.encodePng(image));
}

// ── Foreground para adaptive icon (símbolo blanco transparente) ──
void _createForegroundIcon() {
  final image = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Billetera blanca centrada (zona segura ~66%)
  _roundRect(image, 212, 330, 812, 720, 50, _white);
  _roundRect(image, 212, 330, 812, 455, 50, img.ColorRgba8(180, 210, 255, 255));
  _rect(image, 212, 400, 812, 455, img.ColorRgba8(180, 210, 255, 255));
  _rect(image, 212, 510, 812, 550, img.ColorRgba8(180, 210, 255, 255));

  // Moneda
  _circle(image, 650, 625, 90, img.ColorRgba8(180, 210, 255, 255));
  _circle(image, 650, 625, 76, _white);
  _circle(image, 650, 625, 56, img.ColorRgba8(180, 210, 255, 255));
  _rect(image, 644, 577, 656, 673, _white);
  _rect(image, 626, 595, 674, 608, _white);
  _rect(image, 626, 642, 674, 655, _white);

  File('assets/icon_fg.png').writeAsBytesSync(img.encodePng(image));
}

// ── Logo para splash screen (blanco sobre transparente) ──────────
void _createSplashLogo() {
  final image = img.Image(width: 500, height: 500, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  // Billetera blanca
  _roundRect(image, 50, 130, 450, 400, 40, _white);
  _roundRect(image, 50, 130, 450, 225, 40, img.ColorRgba8(150, 190, 255, 255));
  _rect(image, 50, 188, 450, 225, img.ColorRgba8(150, 190, 255, 255));
  _rect(image, 50, 258, 450, 288, img.ColorRgba8(150, 190, 255, 255));

  // Moneda
  _circle(image, 355, 320, 68, img.ColorRgba8(150, 190, 255, 255));
  _circle(image, 355, 320, 56, _white);
  _circle(image, 355, 320, 40, img.ColorRgba8(150, 190, 255, 255));
  _rect(image, 349, 282, 361, 358, _white);
  _rect(image, 333, 299, 377, 311, _white);
  _rect(image, 333, 329, 377, 341, _white);

  File('assets/splash_logo.png').writeAsBytesSync(img.encodePng(image));
}

// ── Helpers ────────────────────────────────────────────────────
final _white = img.ColorRgba8(255, 255, 255, 255);
final _blue = img.ColorRgba8(21, 101, 192, 255);
final _darkBlue = img.ColorRgba8(13, 71, 161, 255);

void _circle(img.Image im, int cx, int cy, int r, img.Color c) {
  img.fillCircle(im, x: cx, y: cy, radius: r, color: c);
}

void _rect(img.Image im, int x1, int y1, int x2, int y2, img.Color c) {
  for (var y = y1; y <= y2; y++) {
    for (var x = x1; x <= x2; x++) {
      if (x >= 0 && y >= 0 && x < im.width && y < im.height) {
        im.setPixel(x, y, c);
      }
    }
  }
}

void _roundRect(img.Image im, int x1, int y1, int x2, int y2, int r, img.Color c) {
  for (var y = y1; y <= y2; y++) {
    for (var x = x1; x <= x2; x++) {
      if (x < 0 || y < 0 || x >= im.width || y >= im.height) continue;

      final inTL = x < x1 + r && y < y1 + r;
      final inTR = x > x2 - r && y < y1 + r;
      final inBL = x < x1 + r && y > y2 - r;
      final inBR = x > x2 - r && y > y2 - r;

      if (inTL) {
        final dx = x - (x1 + r), dy = y - (y1 + r);
        if (dx * dx + dy * dy > r * r) continue;
      } else if (inTR) {
        final dx = x - (x2 - r), dy = y - (y1 + r);
        if (dx * dx + dy * dy > r * r) continue;
      } else if (inBL) {
        final dx = x - (x1 + r), dy = y - (y2 - r);
        if (dx * dx + dy * dy > r * r) continue;
      } else if (inBR) {
        final dx = x - (x2 - r), dy = y - (y2 - r);
        if (dx * dx + dy * dy > r * r) continue;
      }

      im.setPixel(x, y, c);
    }
  }
}

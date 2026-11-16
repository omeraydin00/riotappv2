import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// Riot'un Data Dragon CDN'i: şampiyon listesi ve portreler buradan geliyor.
// Sürüm numarası artık sabit değil (eskiden 12.19.1 yazılıydı), açılışta en güncel sürüm okunuyor.
class Champion {
  const Champion(this.id, this.name);

  final String id; // resim adresinde kullanılan anahtar, ör. MonkeyKing
  final String name; // ekranda görünen ad, ör. Wukong
}

class DDragonException implements Exception {
  DDragonException(this.message);

  final String message;

  @override
  String toString() => 'DDragonException: $message';
}

class DDragon {
  static const _base = 'https://ddragon.leagueoflegends.com';
  static const _timeout = Duration(seconds: 10);

  static String? _version;
  static List<Champion>? _champions;

  // Liste bir kez indirilip saklanıyor, tekrar oynarken ağa gitmiyoruz
  static Future<List<Champion>> champions() async {
    if (_champions != null) return _champions!;

    final versions = await _getJson('$_base/api/versions.json') as List<dynamic>;
    final version = versions.first as String;
    final body = await _getJson('$_base/cdn/$version/data/tr_TR/champion.json') as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;

    _version = version;
    _champions = [
      for (final value in data.values) Champion(value['id'] as String, value['name'] as String),
    ];
    return _champions!;
  }

  static Future<Uint8List> portrait(Champion champion) async {
    final url = '$_base/cdn/$_version/img/champion/${champion.id}.png';
    final response = await _get(url);
    return response.bodyBytes;
  }

  static Future<dynamic> _getJson(String url) async {
    final response = await _get(url);
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<http.Response> _get(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) {
        throw DDragonException('$url -> ${response.statusCode}');
      }
      return response;
    } on DDragonException {
      rethrow;
    } catch (e) {
      // Bağlantı hatası, zaman aşımı vs. hepsini tek tipte topluyoruz
      throw DDragonException('$url -> $e');
    }
  }
}

// compute() ile ayrı isolate'e gönderilen iş. Web'de isolate yok, orada aynı thread'de çalışıyor
// ama resimler küçük (240x240) olduğu için takılma hissedilmiyor.
class BlendJob {
  const BlendJob(this.first, this.second, this.blurRadius);

  final Uint8List first;
  final Uint8List second;
  final int blurRadius;
}

const blendSize = 240;

// İki portreyi bulanıklaştırıp piksel piksel karıştırır, PNG olarak döner
Uint8List blendPortraits(BlendJob job) {
  const mixRatio = 0.4; // ikinci resmin ağırlığı

  img.Image prepare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw DDragonException('portre çözülemedi');
    // Portrelerin kenarındaki ince koyu çerçeveyi at
    final cropped = img.copyCrop(decoded, x: 3, y: 3, width: decoded.width - 6, height: decoded.height - 6);
    final resized = img.copyResize(
      cropped,
      width: blendSize,
      height: blendSize,
      interpolation: img.Interpolation.cubic,
    );

    // gaussianBlur resmin dışını siyah sayıyor, kenarlar kararıyordu.
    // Önce kenar piksellerini dışarı doğru uzatıp bulanıklaştırıyor, sonra ortayı geri kesiyoruz.
    final pad = job.blurRadius * 2;
    final padded = img.Image(width: blendSize + pad * 2, height: blendSize + pad * 2);
    for (final pixel in padded) {
      final source = resized.getPixel(
        (pixel.x - pad).clamp(0, blendSize - 1),
        (pixel.y - pad).clamp(0, blendSize - 1),
      );
      pixel.setRgb(source.r, source.g, source.b);
    }
    final blurred = img.gaussianBlur(padded, radius: job.blurRadius);
    return img.copyCrop(blurred, x: pad, y: pad, width: blendSize, height: blendSize);
  }

  final first = prepare(job.first);
  final second = prepare(job.second);
  final combined = img.Image(width: blendSize, height: blendSize);

  for (final pixel in combined) {
    final a = first.getPixel(pixel.x, pixel.y);
    final b = second.getPixel(pixel.x, pixel.y);
    pixel.setRgb(
      a.r * (1 - mixRatio) + b.r * mixRatio,
      a.g * (1 - mixRatio) + b.g * mixRatio,
      a.b * (1 - mixRatio) + b.b * mixRatio,
    );
  }

  return img.encodePng(combined);
}

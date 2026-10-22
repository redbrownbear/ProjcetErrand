import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/kit.dart';

/// 고른 사진 한 장
typedef PickedPhoto = ({Uint8List bytes, String contentType});

/// 카메라 · 앨범에서 사진 한 장을 고른다(거래 사진 · 채팅 사진 공용). 고르지 않으면 null.
/// 긴 변 1600px · 품질 80으로 줄여 올린다(보통 1MB 안쪽). 권한 등으로 못 가져오면 예외를 그대로 던진다.
Future<PickedPhoto?> pickPhoto(BuildContext context) async {
  final src = await showSheet<ImageSource>(
    context,
    (ctx) => SheetFrame(
      title: '사진 고르기',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('카메라로 찍기'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('앨범에서 고르기'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (src == null) return null;
  final file = await ImagePicker().pickImage(source: src, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
  if (file == null) return null;
  final name = file.name.toLowerCase();
  final type = name.endsWith('.png') ? 'image/png' : (name.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
  return (bytes: await file.readAsBytes(), contentType: type);
}

/// 사진 크게 보기(손가락으로 확대)
Future<void> showPhotoViewer(BuildContext context, Uint8List data) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog(
    insetPadding: const EdgeInsets.all(12),
    backgroundColor: Colors.black,
    child: Stack(
      children: [
        InteractiveViewer(child: Center(child: Image.memory(data, fit: BoxFit.contain))),
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
      ],
    ),
  ),
);

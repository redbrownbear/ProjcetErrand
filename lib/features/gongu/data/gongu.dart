import '../models/gongu.dart';

const gonguSteps = [
  GonguStep(1, '기본 할인가'),
  GonguStep(3, '+500원'),
  GonguStep(5, '+2,000원'),
  GonguStep(10, '+5,000원'),
];

const gonguItems = [
  Gongu(id: 'g1', icon: '🧴', brand: '홈케어', title: '프리미엄 핸드워시 3종', list: 39000, price: 29900, joined: 3, target: 5, steps: gonguSteps),
  Gongu(id: 'g2', icon: '🍯', brand: '델리', title: '수제 그래놀라 대용량', list: 24000, price: 18900, joined: 7, target: 10, steps: gonguSteps),
  Gongu(id: 'g3', icon: '🧦', brand: '리빙', title: '무지 순면 양말 10족', list: 19000, price: 12900, joined: 2, target: 5, steps: gonguSteps),
];

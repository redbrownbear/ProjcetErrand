/**
 * 모든 함수에 공통으로 거는 옵션.
 *
 * - 리전: 서울(asia-northeast3) 하나. Firestore와 같은 곳에 둬야 지연·비용이 적다.
 * - maxInstances: 비정상 호출 폭주 때 비용이 끝없이 늘지 않게 막는 상한.
 * - App Check: 처음엔 꺼 두고(모니터링) 출시 직전에 켠다.
 *   functions/.env.<프로젝트 id> 에 ENFORCE_APP_CHECK=true 를 넣고 다시 배포하면 된다.
 */
import { setGlobalOptions } from 'firebase-functions/v2';

export const REGION = 'asia-northeast3';

setGlobalOptions({ region: REGION, maxInstances: 10 });

export const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === 'true';

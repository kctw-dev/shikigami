/**
 * ci-firebase-login.js — CI 環境 Firebase 登入模板
 * ============================================================
 * 使用方式：
 *   1. 將此檔案複製至消費端專案的 scripts/ 或 tests/ 目錄
 *   2. 將所有 YOUR_XXX 佔位符替換為實際值（或改為環境變數讀取）
 *   3. 在 CI 環境（GitHub Actions 等）設定對應的 Secrets
 *   4. 在 E2E 測試前執行此腳本取得 ID Token，供後續 API 呼叫使用
 *
 * 流程說明：
 *   Service Account JSON（環境變數）
 *     → firebase-admin SDK 建立 Custom Token
 *     → 呼叫 Firebase Auth REST API 換取 ID Token
 *     → 輸出 ID Token 供 E2E 測試使用
 *
 * 必要環境變數（在 CI 的 Secrets / Env 設定）：
 *   FIREBASE_SERVICE_ACCOUNT_JSON：Service Account 的 JSON 字串
 *   FIREBASE_WEB_API_KEY：Firebase 專案的 Web API Key（僅用於 token exchange）
 *
 * 必要套件：
 *   npm install firebase-admin node-fetch
 *   （或使用專案既有的 fetch polyfill）
 * ============================================================
 */

'use strict';

const admin = require('firebase-admin');

// ============================================================
// 消費端自行填入區域
// ============================================================

/**
 * Firebase 專案 ID
 * 替換為實際值，或從環境變數讀取：
 *   const PROJECT_ID = process.env.YOUR_FIREBASE_PROJECT_ID;
 */
const PROJECT_ID = 'YOUR_PROJECT_ID';

/**
 * 要模擬登入的測試使用者 UID
 * 此 UID 必須在 Firebase Authentication 中已存在
 * 替換為實際值，或從環境變數讀取：
 *   const TEST_USER_UID = process.env.YOUR_TEST_USER_UID;
 */
const TEST_USER_UID = 'YOUR_TEST_USER_UID';

/**
 * Firebase Web API Key（用於 Custom Token → ID Token 的 REST 交換）
 * 從環境變數讀取（切勿硬編碼）：
 */
const WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;

// ============================================================
// 主要邏輯（通常不需要修改以下部分）
// ============================================================

/**
 * 初始化 firebase-admin SDK
 * 使用 FIREBASE_SERVICE_ACCOUNT_JSON 環境變數中的 Service Account JSON
 *
 * @returns {admin.app.App} Firebase Admin App 實例
 */
function initializeFirebaseAdmin() {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  if (!serviceAccountJson) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT_JSON 環境變數未設定。\n' +
      '請在 CI Secrets 中設定 Service Account JSON 字串。'
    );
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch (parseError) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT_JSON 解析失敗，請確認格式為有效的 JSON 字串。\n' +
      `解析錯誤：${parseError.message}`
    );
  }

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID,
    });
  }

  return admin.app();
}

/**
 * 使用 firebase-admin SDK 為指定 UID 產生 Custom Token
 *
 * @param {string} uid 目標使用者的 Firebase UID
 * @param {Object} [additionalClaims] 額外的 JWT claims（可選）
 * @returns {Promise<string>} Custom Token 字串
 */
async function createCustomToken(uid, additionalClaims = {}) {
  try {
    const customToken = await admin.auth().createCustomToken(uid, additionalClaims);
    return customToken;
  } catch (error) {
    throw new Error(`Custom Token 建立失敗（UID: ${uid}）：${error.message}`);
  }
}

/**
 * 呼叫 Firebase Auth REST API，將 Custom Token 換取 ID Token
 *
 * 使用 signInWithCustomToken REST 端點：
 * https://firebase.google.com/docs/reference/rest/auth#section-sign-in-with-custom-token
 *
 * @param {string} customToken 由 firebase-admin 產生的 Custom Token
 * @returns {Promise<{idToken: string, refreshToken: string, expiresIn: string}>}
 */
async function exchangeCustomTokenForIdToken(customToken) {
  if (!WEB_API_KEY) {
    throw new Error(
      'FIREBASE_WEB_API_KEY 環境變數未設定。\n' +
      '此 API Key 用於 Custom Token → ID Token 的 REST 交換，請在 CI 環境設定。'
    );
  }

  const endpoint = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${WEB_API_KEY}`;

  // 使用 Node.js 18+ 內建 fetch（若需支援舊版，請引入 node-fetch）
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token: customToken,
      returnSecureToken: true,
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(
      `Firebase Auth REST API 回傳錯誤（HTTP ${response.status}）：${errorBody}`
    );
  }

  const data = await response.json();

  if (!data.idToken) {
    throw new Error('Firebase Auth REST API 回應中缺少 idToken 欄位。');
  }

  return {
    idToken: data.idToken,
    refreshToken: data.refreshToken,
    expiresIn: data.expiresIn,
  };
}

/**
 * 主流程：Service Account → Custom Token → ID Token
 *
 * 成功時將 ID Token 印至 stdout，可供 CI 後續步驟捕獲：
 *   ID_TOKEN=$(node scripts/ci-firebase-login.js)
 *
 * @returns {Promise<void>}
 */
async function main() {
  console.error('[ci-firebase-login] 初始化 Firebase Admin SDK...');
  initializeFirebaseAdmin();

  console.error(`[ci-firebase-login] 為 UID "${TEST_USER_UID}" 建立 Custom Token...`);
  const customToken = await createCustomToken(TEST_USER_UID);

  console.error('[ci-firebase-login] 換取 ID Token...');
  const { idToken, expiresIn } = await exchangeCustomTokenForIdToken(customToken);

  console.error(`[ci-firebase-login] 完成。Token 有效期：${expiresIn} 秒`);

  // 僅將 ID Token 輸出至 stdout，方便 shell 捕獲
  // 其餘日誌均輸出至 stderr，避免污染捕獲結果
  process.stdout.write(idToken);
}

main().catch((error) => {
  console.error(`[ci-firebase-login] 錯誤：${error.message}`);
  process.exit(1);
});

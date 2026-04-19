/// ─── CampusEats — Notifications Service (Phase 11) ────────────────────────
///
/// Wraps Firebase Admin SDK to send FCM push notifications.
///
/// Design principles:
///  - Lazy init: only initialises Firebase when all three env vars are present.
///  - All errors are caught and logged — notification failure NEVER propagates to order flow.
///  - Stale / invalid FCM tokens are handled silently.
///
/// Required environment variables (on Render):
///   FIREBASE_PROJECT_ID   — Firebase project ID (e.g. my-campus-eats)
///   FIREBASE_CLIENT_EMAIL — service account email
///   FIREBASE_PRIVATE_KEY  — private key, stored as single-line with literal \n sequences
///
/// FIREBASE_SERVICE_ACCOUNT_JSON is no longer required or used.

import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

// firebase-admin is loaded dynamically so the app still boots if it is
// not installed yet (developers running locally without Firebase).
// eslint-disable-next-line @typescript-eslint/no-require-imports
let admin: typeof import('firebase-admin') | null = null;

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private ready = false;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit() {
    await this._initFirebase();
  }

  private async _initFirebase() {
    // ── Read the three separate Render env vars ──────────────────────────────
    const projectId   = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    // Render stores private keys as a single line with literal \n sequences —
    // replace them with real newlines so the PEM is valid.
    const privateKey  = this.config.get<string>('FIREBASE_PRIVATE_KEY')
      ?.replace(/\\n/g, '\n');

    // ── Validate — log exactly which vars are missing and exit gracefully ────
    const missing: string[] = [];
    if (!projectId)   missing.push('FIREBASE_PROJECT_ID');
    if (!clientEmail) missing.push('FIREBASE_CLIENT_EMAIL');
    if (!privateKey)  missing.push('FIREBASE_PRIVATE_KEY');

    if (missing.length > 0) {
      this.logger.warn(
        `[FCM] Firebase env vars missing (${missing.join(', ')}) — push notifications disabled`,
      );
      return;
    }

    // ── Dynamic import — keeps the app bootable without firebase-admin ───────
    try {
      const mod = await import('firebase-admin').catch(() => null);
      if (!mod) {
        this.logger.error('[FCM] firebase-admin package could not be loaded');
        return;
      }
      // firebase-admin is CommonJS. When the NestJS host runs as ESM the
      // dynamic import wraps it: the real module sits on mod.default.
      // Fall back to mod itself for CJS contexts (local dev / Jest).
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      admin = ((mod as any).default ?? mod) as typeof import('firebase-admin');

      // ── Idempotent init — safe in HMR / watch mode ───────────────────────
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId:   projectId!,
            clientEmail: clientEmail!,
            privateKey:  privateKey!,
          }),
        });
      }

      this.ready = true;
      this.logger.log(
        `[FCM] Firebase Admin initialised — project: ${projectId}`,
      );
    } catch (err) {
      // Log the reason clearly — never log the raw private key
      this.logger.error(
        `[FCM] Firebase init failed: ${(err as Error).message}`,
      );
    }
  }

  /**
   * Sends a push notification to a single FCM token.
   * Silent on any failure — never throws.
   */
  async sendToToken(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.ready || !admin) {
      this.logger.debug('[FCM] Not ready — notification skipped');
      return;
    }
    if (!token || token.trim().length === 0) {
      this.logger.debug('[FCM] Empty token — notification skipped');
      return;
    }

    try {
      const result = await admin.messaging().send({
        token,
        notification: { title, body },
        data,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'campus_eats_orders',
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      });
      this.logger.log(`[FCM] Sent to token ...${token.slice(-8)} → ${result}`);
    } catch (err: any) {
      // firebase-admin error codes for stale tokens — no action needed
      const staleCode =
        err?.errorInfo?.code === 'messaging/registration-token-not-registered' ||
        err?.errorInfo?.code === 'messaging/invalid-registration-token';
      if (staleCode) {
        this.logger.warn(`[FCM] Stale/invalid token: ${token.slice(-8)}`);
      } else {
        this.logger.error(`[FCM] Send failed: ${err?.message}`);
      }
    }
  }

  /**
   * Sends a silent data-only push (used for canteen new-order awareness
   * as a supplement to the 8-second poll). Silent = no lock-screen banner.
   */
  async sendDataToToken(
    token: string,
    data: Record<string, string>,
  ): Promise<void> {
    if (!this.ready || !admin) return;
    if (!token?.trim()) return;

    try {
      await admin.messaging().send({ token, data });
    } catch (err: any) {
      this.logger.warn(`[FCM] Silent data push failed: ${err?.message}`);
    }
  }
}

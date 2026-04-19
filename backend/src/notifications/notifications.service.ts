/// ─── CampusEats — Notifications Service (Phase 11) ────────────────────────
///
/// Wraps Firebase Admin SDK to send FCM push notifications.
///
/// Design principles:
///  - Lazy init: only tries to initialise Firebase if FIREBASE_SERVICE_ACCOUNT_JSON is set.
///  - All errors are caught and logged — notification failure NEVER propagates to order flow.
///  - Stale / invalid FCM tokens are handled silently.
///
/// Required environment variable (on Render):
///   FIREBASE_SERVICE_ACCOUNT_JSON — the full JSON content of your
///   Firebase service account key file, on a single line.

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
    const raw = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (!raw) {
      this.logger.warn(
        '[FCM] FIREBASE_SERVICE_ACCOUNT_JSON not set — push notifications disabled',
      );
      return;
    }

    try {
      // Dynamic import so build doesn't fail if firebase-admin isn't installed
      admin = await import('firebase-admin').catch(() => null);
      if (!admin) {
        this.logger.error('[FCM] firebase-admin could not be loaded');
        return;
      }

      const serviceAccount = JSON.parse(raw);

      // Only initialise once (HMR-safe)
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
      }
      this.ready = true;
      this.logger.log('[FCM] Firebase Admin initialised successfully');
    } catch (err) {
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

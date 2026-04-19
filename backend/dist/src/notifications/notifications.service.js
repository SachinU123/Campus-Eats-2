"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var NotificationsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
let admin = null;
let NotificationsService = NotificationsService_1 = class NotificationsService {
    config;
    logger = new common_1.Logger(NotificationsService_1.name);
    ready = false;
    constructor(config) {
        this.config = config;
    }
    async onModuleInit() {
        await this._initFirebase();
    }
    async _initFirebase() {
        const raw = this.config.get('FIREBASE_SERVICE_ACCOUNT_JSON');
        if (!raw) {
            this.logger.warn('[FCM] FIREBASE_SERVICE_ACCOUNT_JSON not set — push notifications disabled');
            return;
        }
        try {
            admin = await import('firebase-admin').catch(() => null);
            if (!admin) {
                this.logger.error('[FCM] firebase-admin could not be loaded');
                return;
            }
            const serviceAccount = JSON.parse(raw);
            if (admin.apps.length === 0) {
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                });
            }
            this.ready = true;
            this.logger.log('[FCM] Firebase Admin initialised successfully');
        }
        catch (err) {
            this.logger.error(`[FCM] Firebase init failed: ${err.message}`);
        }
    }
    async sendToToken(token, title, body, data) {
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
        }
        catch (err) {
            const staleCode = err?.errorInfo?.code === 'messaging/registration-token-not-registered' ||
                err?.errorInfo?.code === 'messaging/invalid-registration-token';
            if (staleCode) {
                this.logger.warn(`[FCM] Stale/invalid token: ${token.slice(-8)}`);
            }
            else {
                this.logger.error(`[FCM] Send failed: ${err?.message}`);
            }
        }
    }
    async sendDataToToken(token, data) {
        if (!this.ready || !admin)
            return;
        if (!token?.trim())
            return;
        try {
            await admin.messaging().send({ token, data });
        }
        catch (err) {
            this.logger.warn(`[FCM] Silent data push failed: ${err?.message}`);
        }
    }
};
exports.NotificationsService = NotificationsService;
exports.NotificationsService = NotificationsService = NotificationsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map
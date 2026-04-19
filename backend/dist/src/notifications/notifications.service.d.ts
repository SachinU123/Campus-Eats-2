import { OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
export declare class NotificationsService implements OnModuleInit {
    private readonly config;
    private readonly logger;
    private ready;
    constructor(config: ConfigService);
    onModuleInit(): Promise<void>;
    private _initFirebase;
    sendToToken(token: string, title: string, body: string, data?: Record<string, string>): Promise<void>;
    sendDataToToken(token: string, data: Record<string, string>): Promise<void>;
}

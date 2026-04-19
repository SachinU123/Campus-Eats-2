import { PrismaService } from '../prisma/prisma.service.js';
export type CanteenStatus = 'open' | 'paused' | 'closed';
export interface CanteenOperationalStatus {
    status: CanteenStatus;
    message: string;
    updatedAt: Date | null;
}
export declare class SettingsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getCanteenStatus(): Promise<CanteenOperationalStatus>;
    isOrderingOpen(): Promise<boolean>;
    setCanteenStatus(status: CanteenStatus, message: string): Promise<CanteenOperationalStatus>;
    listStaff(): Promise<{
        id: string;
        phoneNumber: string;
        name: string;
        role: string;
        isActive: boolean;
        createdAt: Date;
    }[]>;
    setStaffActive(id: string, isActive: boolean): Promise<{
        id: string;
        phoneNumber: string;
        name: string;
        role: string;
        isActive: boolean;
    }>;
}

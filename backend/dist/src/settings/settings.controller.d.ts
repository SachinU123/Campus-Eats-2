import { SettingsService } from './settings.service.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
declare class SetCanteenStatusDto {
    status: 'open' | 'paused' | 'closed';
    message?: string;
}
declare class SetStaffActiveDto {
    isActive: boolean;
}
export declare class SettingsController {
    private readonly settings;
    constructor(settings: SettingsService);
    getStatus(): Promise<ApiResponse<import("./settings.service.js").CanteenOperationalStatus>>;
    setStatus(dto: SetCanteenStatusDto, req: any): Promise<ApiResponse<import("./settings.service.js").CanteenOperationalStatus>>;
    listStaff(req: any): Promise<ApiResponse<{
        id: string;
        phoneNumber: string;
        name: string;
        role: string;
        isActive: boolean;
        createdAt: Date;
    }[]>>;
    setStaffActive(id: string, dto: SetStaffActiveDto, req: any): Promise<ApiResponse<{
        id: string;
        phoneNumber: string;
        name: string;
        role: string;
        isActive: boolean;
    }>>;
}
export {};

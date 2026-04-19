import { MenuService } from './menu.service.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
declare class SetUnavailableTodayDto {
    isUnavailableToday: boolean;
}
declare class SetSpecialDto {
    isSpecial: boolean;
    specialLabel?: string;
}
export declare class MenuController {
    private readonly menuService;
    constructor(menuService: MenuService);
    getCategories(): Promise<ApiResponse<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
        emoji: string;
        sortOrder: number;
    }[]>>;
    getItems(category?: string, search?: string): Promise<ApiResponse<({
        category: {
            id: string;
            name: string;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
            emoji: string;
            sortOrder: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        emoji: string;
        isPopular: boolean;
        categoryId: string;
        description: string;
        imageUrl: string;
        price: number;
        isVeg: boolean;
        isAvailable: boolean;
        isUnavailableToday: boolean;
        isSpecial: boolean;
        specialLabel: string;
        prepTimeMinutes: number;
    })[]>>;
    getItemById(id: string): Promise<ApiResponse<any>>;
    getAllItemsForManagement(): Promise<ApiResponse<({
        category: {
            id: string;
            name: string;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
            emoji: string;
            sortOrder: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        emoji: string;
        isPopular: boolean;
        categoryId: string;
        description: string;
        imageUrl: string;
        price: number;
        isVeg: boolean;
        isAvailable: boolean;
        isUnavailableToday: boolean;
        isSpecial: boolean;
        specialLabel: string;
        prepTimeMinutes: number;
    })[]>>;
    setUnavailableToday(id: string, dto: SetUnavailableTodayDto, req: any): Promise<ApiResponse<{
        category: {
            id: string;
            name: string;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
            emoji: string;
            sortOrder: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        emoji: string;
        isPopular: boolean;
        categoryId: string;
        description: string;
        imageUrl: string;
        price: number;
        isVeg: boolean;
        isAvailable: boolean;
        isUnavailableToday: boolean;
        isSpecial: boolean;
        specialLabel: string;
        prepTimeMinutes: number;
    }>>;
    setSpecial(id: string, dto: SetSpecialDto, req: any): Promise<ApiResponse<{
        category: {
            id: string;
            name: string;
            createdAt: Date;
            updatedAt: Date;
            slug: string;
            emoji: string;
            sortOrder: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        emoji: string;
        isPopular: boolean;
        categoryId: string;
        description: string;
        imageUrl: string;
        price: number;
        isVeg: boolean;
        isAvailable: boolean;
        isUnavailableToday: boolean;
        isSpecial: boolean;
        specialLabel: string;
        prepTimeMinutes: number;
    }>>;
}
export {};

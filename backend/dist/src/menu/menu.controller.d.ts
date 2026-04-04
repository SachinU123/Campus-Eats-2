import { MenuService } from './menu.service.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
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
    })[]>>;
    getItemById(id: string): Promise<ApiResponse<any>>;
}

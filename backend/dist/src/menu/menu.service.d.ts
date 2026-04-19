import { PrismaService } from '../prisma/prisma.service.js';
export declare class MenuService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getCategories(): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        slug: string;
        emoji: string;
        sortOrder: number;
    }[]>;
    getItems(categoryId?: string): Promise<({
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
    })[]>;
    getItemById(id: string): Promise<({
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
    }) | null>;
    searchItems(query: string): Promise<({
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
    })[]>;
    getAllItemsForManagement(): Promise<({
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
    })[]>;
    setUnavailableToday(id: string, isUnavailableToday: boolean): Promise<{
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
    }>;
    setSpecial(id: string, isSpecial: boolean, specialLabel?: string): Promise<{
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
    }>;
    checkItemsOrderable(ids: string[]): Promise<{
        id: string;
        name: string;
        reason: string;
    }[]>;
}

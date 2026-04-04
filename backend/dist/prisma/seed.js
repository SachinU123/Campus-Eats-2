"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const pg_1 = require("pg");
const adapter_pg_1 = require("@prisma/adapter-pg");
const client_1 = require("@prisma/client");
const bcrypt = __importStar(require("bcrypt"));
require("dotenv/config");
const connectionString = process.env.DATABASE_URL;
const pool = new pg_1.Pool({ connectionString });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
async function main() {
    console.log('🌱 Seeding CampusEats database...\n');
    const canteenPhone = '9876540000';
    const existingCanteen = await prisma.canteenUser.findUnique({
        where: { phoneNumber: canteenPhone },
    });
    if (!existingCanteen) {
        await prisma.canteenUser.create({
            data: {
                name: 'Canteen Admin',
                phoneNumber: canteenPhone,
                role: 'canteen',
                isActive: true,
            },
        });
        console.log('✅ Canteen user created (phone: 9876540000)');
    }
    else {
        console.log('⏭️  Canteen user already exists');
    }
    const categories = [
        { name: 'Breakfast', slug: 'breakfast', emoji: 'sunrise', sortOrder: 1 },
        { name: 'Snacks', slug: 'snacks', emoji: 'snack', sortOrder: 2 },
        { name: 'Meals', slug: 'meals', emoji: 'meal', sortOrder: 3 },
        { name: 'Thali', slug: 'thali', emoji: 'thali', sortOrder: 4 },
        { name: 'Chinese', slug: 'chinese', emoji: 'chinese', sortOrder: 5 },
        { name: 'Beverages', slug: 'beverages', emoji: 'beverage', sortOrder: 6 },
    ];
    for (const cat of categories) {
        await prisma.menuCategory.upsert({
            where: { slug: cat.slug },
            update: {},
            create: cat,
        });
    }
    console.log('✅ Menu categories seeded');
    const catMap = new Map();
    const allCats = await prisma.menuCategory.findMany();
    for (const c of allCats) {
        catMap.set(c.slug, c.id);
    }
    const menuItems = [
        { categorySlug: 'breakfast', name: 'Poha', description: 'Flattened rice with peas, mustard, and fresh coriander', price: 30, isVeg: true, isPopular: true, emoji: '🍚' },
        { categorySlug: 'breakfast', name: 'Upma', description: 'Semolina cooked with vegetables and spices', price: 30, isVeg: true, isPopular: true, emoji: '🍲' },
        { categorySlug: 'breakfast', name: 'Sheera', description: 'Sweet semolina pudding with saffron and dry fruits', price: 25, isVeg: true, emoji: '🍮' },
        { categorySlug: 'breakfast', name: 'Idli Sambar', description: 'Steamed soft idlis served with hot sambar and chutney', price: 40, isVeg: true, isPopular: true, emoji: '🥙' },
        { categorySlug: 'breakfast', name: 'Sada Dosa', description: 'Thin crispy rice crepe served with sambar and chutney', price: 50, isVeg: true, emoji: '🫓' },
        { categorySlug: 'breakfast', name: 'Masala Dosa', description: 'Crispy dosa filled with spiced potato filling', price: 65, isVeg: true, isPopular: true, emoji: '🫓' },
        { categorySlug: 'breakfast', name: 'Butter Masala Dosa', description: 'Masala dosa prepared with generous butter', price: 75, isVeg: true, emoji: '🫓' },
        { categorySlug: 'breakfast', name: 'Onion Uttapa', description: 'Thick rice pancake topped with caramelized onions', price: 60, isVeg: true, emoji: '🥞' },
        { categorySlug: 'breakfast', name: 'Tomato Uttapa', description: 'Thick rice pancake topped with fresh tomatoes and herbs', price: 60, isVeg: true, emoji: '🥞' },
        { categorySlug: 'breakfast', name: 'Chapati', description: 'Soft whole-wheat flatbread, served plain or with sabji', price: 10, isVeg: true, emoji: '🫓' },
        { categorySlug: 'snacks', name: 'Batata Vada', description: 'Spiced potato dumpling in crispy gram-flour batter', price: 20, isVeg: true, isPopular: true, emoji: '🟡' },
        { categorySlug: 'snacks', name: 'Medu Vada', description: 'Crispy lentil donuts served with sambar and chutney', price: 35, isVeg: true, emoji: '🍩' },
        { categorySlug: 'snacks', name: 'Vada Pav', description: 'Mumbai street food - spicy vada in a soft pav bun', price: 25, isVeg: true, isPopular: true, emoji: '🍔' },
        { categorySlug: 'snacks', name: 'Samosa Pav', description: 'Crispy samosa served with pav and green chutney', price: 30, isVeg: true, isPopular: true, emoji: '🥐' },
        { categorySlug: 'meals', name: 'Veg Thali', description: 'Dal, 2 sabji, rice, chapati, papad, and salad', price: 100, isVeg: true, isPopular: true, emoji: '🍽️' },
        { categorySlug: 'meals', name: 'Dal Tadka', description: 'Yellow dal tempered with ghee, cumin, and dry red chilli', price: 70, isVeg: true, emoji: '🫕' },
        { categorySlug: 'meals', name: 'Aloo Mutter', description: 'Potato and green peas in a tomato-onion gravy', price: 75, isVeg: true, emoji: '🥘' },
        { categorySlug: 'meals', name: 'Paneer Mutter', description: 'Paneer and green peas in a creamy onion-tomato gravy', price: 110, isVeg: true, isPopular: true, emoji: '🥘' },
        { categorySlug: 'meals', name: 'Paneer Tikka Masala', description: 'Grilled paneer in a smoky, creamy tikka sauce', price: 130, isVeg: true, isPopular: true, emoji: '🥘' },
        { categorySlug: 'meals', name: 'Paneer Biryani', description: 'Basmati rice layered with spiced paneer and saffron', price: 140, isVeg: true, isPopular: true, emoji: '🍛' },
        { categorySlug: 'meals', name: 'Jeera Rice', description: 'Steamed basmati rice tempered with cumin seeds and ghee', price: 70, isVeg: true, emoji: '🍚' },
        { categorySlug: 'meals', name: 'Puri Bhaji', description: 'Deep-fried puris served with spiced potato bhaji', price: 60, isVeg: true, isPopular: true, emoji: '🥙' },
        { categorySlug: 'meals', name: 'Pav Bhaji', description: 'Spiced mashed vegetables with buttery pav buns', price: 70, isVeg: true, isPopular: true, emoji: '🍲' },
        { categorySlug: 'thali', name: 'Special Thali', description: 'Paneer curry, dal, rice, 3 chapati, salad, and sweet', price: 130, isVeg: true, isPopular: true, emoji: '🍽️' },
        { categorySlug: 'thali', name: 'Punjabi Thali', description: 'Dal makhani, paneer, raita, rice, and 3 rotis', price: 140, isVeg: true, emoji: '🍽️' },
        { categorySlug: 'thali', name: 'South Indian Thali', description: 'Rice, sambar, rasam, 2 sabji, papad, dessert', price: 120, isVeg: true, emoji: '🍽️' },
        { categorySlug: 'chinese', name: 'Veg Fried Rice', description: 'Chinese-style stir-fried rice with mixed vegetables', price: 90, isVeg: true, isPopular: true, emoji: '🍚' },
        { categorySlug: 'chinese', name: 'Hakka Noodles', description: 'Stir-fried noodles tossed with vegetables and sauces', price: 90, isVeg: true, isPopular: true, emoji: '🍜' },
        { categorySlug: 'chinese', name: 'Chilli Paneer', description: 'Crispy paneer tossed in spicy Indo-Chinese chilli sauce', price: 130, isVeg: true, isPopular: true, emoji: '🥘' },
        { categorySlug: 'chinese', name: 'Manchurian', description: 'Crispy veggie balls in a tangy Manchurian sauce', price: 100, isVeg: true, emoji: '🍲' },
        { categorySlug: 'chinese', name: 'Spring Rolls', description: 'Crispy golden rolls stuffed with veggies, served with dip', price: 80, isVeg: true, emoji: '🥟' },
        { categorySlug: 'chinese', name: 'Schezwan Fried Rice', description: 'Spicy Schezwan-style fried rice with veggies', price: 100, isVeg: true, emoji: '🍚' },
        { categorySlug: 'beverages', name: 'Tea', description: 'Freshly brewed milk tea with ginger and cardamom', price: 12, isVeg: true, isPopular: true, emoji: '☕' },
        { categorySlug: 'beverages', name: 'Coffee', description: 'Hot instant coffee with milk and sugar', price: 15, isVeg: true, emoji: '☕' },
        { categorySlug: 'beverages', name: 'Cold Drink', description: 'Chilled cold drink (Pepsi / Sprite / Mirinda)', price: 25, isVeg: true, emoji: '🥤' },
    ];
    let itemCount = 0;
    for (const item of menuItems) {
        const catId = catMap.get(item.categorySlug);
        if (!catId)
            continue;
        const existing = await prisma.menuItem.findFirst({
            where: { name: item.name, categoryId: catId },
        });
        if (!existing) {
            await prisma.menuItem.create({
                data: {
                    categoryId: catId,
                    name: item.name,
                    description: item.description,
                    price: item.price,
                    isVeg: item.isVeg,
                    isPopular: item.isPopular || false,
                    emoji: item.emoji || '',
                },
            });
            itemCount++;
        }
    }
    console.log(`✅ ${itemCount} menu items seeded`);
    const demoEmail = 'demo@campuseats.dev';
    const existingDemo = await prisma.student.findUnique({
        where: { email: demoEmail },
    });
    if (!existingDemo) {
        const hash = await bcrypt.hash('demo1234', 12);
        await prisma.student.create({
            data: {
                email: demoEmail,
                name: 'Demo Student',
                phoneNumber: '9000000001',
                passwordHash: hash,
            },
        });
        console.log('✅ Demo student created (demo@campuseats.dev / demo1234)');
    }
    console.log('\n🎉 Seed completed!\n');
}
main()
    .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map
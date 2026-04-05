import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import 'dotenv/config';

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🌱 Seeding CampusEats database...\n');

  // ─── Canteen User (manually inserted — no public registration) ───
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
  } else {
    console.log('⏭️  Canteen user already exists');
  }

  // ─── Menu Categories ──────────────────────────────────────────
  const categories = [
    { name: 'Breakfast', slug: 'breakfast', emoji: '🌅', sortOrder: 1 },
    { name: 'Snacks', slug: 'snacks', emoji: '🍟', sortOrder: 2 },
    { name: 'Main Course', slug: 'main_course', emoji: '🍽️', sortOrder: 3 },
    { name: 'Rice & Noodles', slug: 'rice_noodles', emoji: '🍜', sortOrder: 4 },
    { name: 'Beverages', slug: 'beverages', emoji: '☕', sortOrder: 5 },
    { name: 'Breads / Sides', slug: 'breads', emoji: '🫓', sortOrder: 6 },
  ];

  for (const cat of categories) {
    await prisma.menuCategory.upsert({
      where: { slug: cat.slug },
      update: {},
      create: cat,
    });
  }
  console.log('✅ Menu categories seeded');

  // ─── Get category IDs ────────────────────────────────────────
  const catMap = new Map<string, string>();
  const allCats = await prisma.menuCategory.findMany();
  for (const c of allCats) {
    catMap.set(c.slug, c.id);
  }

  // ─── Menu Items ──────────────────────────────────────────────
  const menuItems = [
    // BREAKFAST
    { categorySlug: 'breakfast', name: 'Poha', description: 'Flattened rice with peas, mustard, and fresh coriander', price: 30, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍚' },
    { categorySlug: 'breakfast', name: 'Upma', description: 'Semolina cooked with vegetables and spices', price: 30, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍲' },
    { categorySlug: 'breakfast', name: 'Sheera', description: 'Sweet semolina pudding with saffron and dry fruits', price: 25, isVeg: true, isAvailable: true, emoji: '🍮' },
    { categorySlug: 'breakfast', name: 'Idli Sambhar', description: 'Steamed soft idlis served with hot sambar and chutney', price: 40, isVeg: true, isPopular: true, isAvailable: true, emoji: '🥙' },
    { categorySlug: 'breakfast', name: 'Sada Dosa', description: 'Thin crispy rice crepe served with sambar and chutney', price: 50, isVeg: true, isAvailable: true, emoji: '🫓' },
    { categorySlug: 'breakfast', name: 'Masala Dosa', description: 'Crispy dosa filled with spiced potato filling', price: 65, isVeg: true, isPopular: true, isAvailable: true, emoji: '🫓' },
    { categorySlug: 'breakfast', name: 'Butter Masala Dosa', description: 'Masala dosa prepared with generous butter', price: 75, isVeg: true, isAvailable: true, emoji: '🫓' },
    { categorySlug: 'breakfast', name: 'Onion Uttapa', description: 'Thick rice pancake topped with caramelized onions', price: 60, isVeg: true, isAvailable: true, emoji: '🥞' },
    { categorySlug: 'breakfast', name: 'Tomato Uttapa', description: 'Thick rice pancake topped with fresh tomatoes and herbs', price: 60, isVeg: true, isAvailable: true, emoji: '🥞' },
    
    // SNACKS
    { categorySlug: 'snacks', name: 'Batata Wada', description: 'Spiced potato dumpling in crispy gram-flour batter', price: 20, isVeg: true, isPopular: true, isAvailable: true, emoji: '🟡' },
    { categorySlug: 'snacks', name: 'Medu Wada', description: 'Crispy lentil donuts served with sambar and chutney', price: 35, isVeg: true, isAvailable: true, emoji: '🍩' },
    { categorySlug: 'snacks', name: 'Vada Pav', description: 'Mumbai street food - spicy vada in a soft pav bun', price: 25, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍔' },
    { categorySlug: 'snacks', name: 'Samosa Pav', description: 'Crispy samosa served with pav and green chutney', price: 30, isVeg: true, isPopular: true, isAvailable: true, emoji: '🥐' },
    { categorySlug: 'snacks', name: 'Samosa', description: 'Crispy fried savory pastry with potato filling', price: 0, isVeg: true, isAvailable: false, emoji: '🥟' },
    { categorySlug: 'snacks', name: 'Dahi Wada', description: 'Lentil dumplings soaked in sweet yogurt', price: 0, isVeg: true, isAvailable: false, emoji: '🥣' },
    { categorySlug: 'snacks', name: 'Pav Bhaji', description: 'Spiced mashed vegetables with buttery pav buns', price: 70, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍲' },
    { categorySlug: 'snacks', name: 'Puri Bhaji', description: 'Deep-fried puris served with spiced potato bhaji', price: 60, isVeg: true, isPopular: true, isAvailable: true, emoji: '🥙' },
    
    // MAIN COURSE
    { categorySlug: 'main_course', name: 'Dal Tadka', description: 'Yellow dal tempered with ghee, cumin, and dry red chilli', price: 70, isVeg: true, isAvailable: true, emoji: '🫕' },
    { categorySlug: 'main_course', name: 'Veg Kolhapuri', description: 'Spicy mixed vegetable curry originating from Kolhapur', price: 0, isVeg: true, isAvailable: false, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Paneer Makhanwala', description: 'Rich paneer curry cooked in a buttery tomato sauce', price: 0, isVeg: true, isAvailable: false, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Paneer Mutter', description: 'Paneer and green peas in a creamy onion-tomato gravy', price: 110, isVeg: true, isPopular: true, isAvailable: true, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Alu Mutter', description: 'Potato and green peas in a tomato-onion gravy', price: 75, isVeg: true, isAvailable: true, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Paneer Masala', description: 'Paneer cubes in a spiced onion-tomato gravy', price: 0, isVeg: true, isAvailable: false, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Paneer Burji', description: 'Scrambled paneer tossed with onions and spices', price: 0, isVeg: true, isAvailable: false, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Paneer Tikka Masala', description: 'Grilled paneer in a smoky, creamy tikka sauce', price: 130, isVeg: true, isPopular: true, isAvailable: true, emoji: '🥘' },
    { categorySlug: 'main_course', name: 'Spl Thali', description: 'Special grand meal portions', price: 130, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍽️' },
    { categorySlug: 'main_course', name: 'Punjabi Thali', description: 'Punjabi style assorted dishes with roti and rice', price: 140, isVeg: true, isAvailable: true, emoji: '🍽️' },

    // RICE & NOODLES
    { categorySlug: 'rice_noodles', name: 'Paneer Biryani', description: 'Basmati rice layered with spiced paneer and saffron', price: 140, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍛' },
    { categorySlug: 'rice_noodles', name: 'Kolhapuri Biryani', description: 'Spicy fragrant biryani prepared Kolhapuri style', price: 0, isVeg: true, isAvailable: false, emoji: '🍛' },
    { categorySlug: 'rice_noodles', name: 'Paneer Pulao', description: 'Fragrant rice pulao packed with soft paneer cubes', price: 0, isVeg: true, isAvailable: false, emoji: '🍛' },
    { categorySlug: 'rice_noodles', name: 'Veg Fried Rice', description: 'Chinese-style stir-fried rice with mixed vegetables', price: 90, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍚' },
    { categorySlug: 'rice_noodles', name: 'Fried Rice', description: 'Classic stir-fried rice', price: 0, isVeg: true, isAvailable: false, emoji: '🍚' },
    { categorySlug: 'rice_noodles', name: 'Noodles', description: 'Stir-fried noodles tossed with vegetables and sauces', price: 90, isVeg: true, isPopular: true, isAvailable: true, emoji: '🍜' },

    // BEVERAGES
    { categorySlug: 'beverages', name: 'Tea', description: 'Freshly brewed milk tea with ginger and cardamom', price: 12, isVeg: true, isPopular: true, isAvailable: true, emoji: '☕' },
    { categorySlug: 'beverages', name: 'Coffee', description: 'Hot instant coffee with milk and sugar', price: 15, isVeg: true, isAvailable: true, emoji: '☕' },

    // BREADS / SIDES
    { categorySlug: 'breads', name: 'Chapati', description: 'Soft whole-wheat flatbread', price: 10, isVeg: true, isAvailable: true, emoji: '🫓' },
    { categorySlug: 'breads', name: 'Chapati Bhaji', description: 'Soft whole-wheat flatbread served with dry vegetable preparation', price: 0, isVeg: true, isAvailable: false, emoji: '🌮' },
  ];

  let itemCount = 0;
  for (const item of menuItems) {
    const catId = catMap.get(item.categorySlug);
    if (!catId) continue;

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
          isAvailable: item.isAvailable,
          emoji: item.emoji || '',
        },
      });
      itemCount++;
    } else {
      // Update existing item to sync availability and price if needed
      await prisma.menuItem.update({
        where: { id: existing.id },
        data: {
          price: item.price,
          isAvailable: item.isAvailable,
          emoji: item.emoji,
          description: item.description
        }
      });
    }
  }
  console.log(`✅ ${itemCount} new menu items seeded (existing updated)`);

  // ─── Optional: Demo Student ──────────────────────────────────
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

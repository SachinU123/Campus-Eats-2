import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import 'dotenv/config';

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function check() {
  const user = await prisma.canteenUser.findUnique({
    where: { phoneNumber: '9876540000' }
  });
  console.log("Canteen User:", user);

  const otps = await prisma.otpCode.findMany({
    orderBy: { createdAt: 'desc' },
    take: 5
  });
  console.log("Recent OTPs:", otps);
  
  process.exit();
}
check();

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const pg_1 = require("pg");
const adapter_pg_1 = require("@prisma/adapter-pg");
const client_1 = require("@prisma/client");
require("dotenv/config");
const connectionString = process.env.DATABASE_URL;
const pool = new pg_1.Pool({ connectionString });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
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
//# sourceMappingURL=check_otp.js.map
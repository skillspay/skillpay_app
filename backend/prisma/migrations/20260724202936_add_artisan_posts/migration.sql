-- AlterTable
ALTER TABLE "artisans" ADD COLUMN     "cover_letter" TEXT;

-- CreateTable
CREATE TABLE "artisan_posts" (
    "id" TEXT NOT NULL,
    "artisan_id" TEXT NOT NULL,
    "title" TEXT,
    "description" TEXT,
    "image_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "artisan_posts_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "artisan_posts" ADD CONSTRAINT "artisan_posts_artisan_id_fkey" FOREIGN KEY ("artisan_id") REFERENCES "artisans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

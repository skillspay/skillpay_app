-- AlterTable
ALTER TABLE "artisans" ADD COLUMN     "based_in" TEXT,
ADD COLUMN     "work_preference" TEXT;

-- AlterTable
ALTER TABLE "jobs" ADD COLUMN     "timeline" TEXT;

-- CreateIndex
CREATE INDEX "artisans_verification_status_idx" ON "artisans"("verification_status");

-- CreateIndex
CREATE INDEX "artisans_availability_status_idx" ON "artisans"("availability_status");

-- CreateIndex
CREATE INDEX "bookings_status_idx" ON "bookings"("status");

-- CreateIndex
CREATE INDEX "bookings_artisan_id_idx" ON "bookings"("artisan_id");

-- CreateIndex
CREATE INDEX "bookings_homeowner_id_idx" ON "bookings"("homeowner_id");

-- CreateIndex
CREATE INDEX "job_applications_job_id_idx" ON "job_applications"("job_id");

-- CreateIndex
CREATE INDEX "job_applications_artisan_id_idx" ON "job_applications"("artisan_id");

-- CreateIndex
CREATE INDEX "job_applications_status_idx" ON "job_applications"("status");

-- CreateIndex
CREATE INDEX "jobs_status_idx" ON "jobs"("status");

-- CreateIndex
CREATE INDEX "jobs_category_id_idx" ON "jobs"("category_id");

-- CreateIndex
CREATE INDEX "jobs_homeowner_id_idx" ON "jobs"("homeowner_id");

-- CreateIndex
CREATE INDEX "messages_conversation_id_idx" ON "messages"("conversation_id");

-- CreateIndex
CREATE INDEX "messages_created_at_idx" ON "messages"("created_at");

-- CreateIndex
CREATE INDEX "notifications_user_id_idx" ON "notifications"("user_id");

-- CreateIndex
CREATE INDEX "notifications_read_idx" ON "notifications"("read");

-- CreateIndex
CREATE INDEX "users_role_idx" ON "users"("role");

-- CreateIndex
CREATE INDEX "users_status_idx" ON "users"("status");

# Goal Description

The user wants to display real data for the "Cover Letter" and "Recent Posts" sections on the Artisan Profile screen in the Customer App. Currently, these sections are hardcoded mockups.

Since the database does not currently have a dedicated `ArtisanPost` model or a generic `coverLetter` field on the `Artisan` profile (only on specific job applications), we need to update the database schema, the backend API, and the customer app to fetch and display this data.

## User Review Required

> [!WARNING]
> This plan involves database schema changes. Please review the proposed `ArtisanPost` model and the new `coverLetter` field to ensure they meet your requirements. 
> 
> Also, this plan will update the backend and the **customer app** to display the posts. Do you also want me to build the UI in the **worker app** for artisans to actually create these posts right now, or should we just build the database/API/customer-view first?

## Proposed Changes

### Database & Backend

#### [MODIFY] `backend/prisma/schema.prisma`
- Add `coverLetter String?` to the `Artisan` model.
- Create a new `ArtisanPost` model to store artisan portfolio posts:
  ```prisma
  model ArtisanPost {
    id          String   @id @default(uuid())
    artisanId   String   @map("artisan_id")
    title       String?
    description String?
    imageUrl    String?  @map("image_url")
    createdAt   DateTime @default(now()) @map("created_at")
    updatedAt   DateTime @updatedAt @map("updated_at")

    artisan     Artisan  @relation(fields: [artisanId], references: [id], onDelete: Cascade)
    @@map("artisan_posts")
  }
  ```
- Run `npx prisma db push` (or `migrate dev`) to update the Supabase database and regenerate the Prisma client.

#### [MODIFY] `backend/src/modules/artisans/artisans.controller.ts` & `artisans.service.ts`
- Update the `ARTISAN_INCLUDE` constant to include `posts: { orderBy: { createdAt: 'desc' } }`.
- Allow updating the `coverLetter` in the `updateProfile` PATCH endpoint.

### Customer App

#### [NEW] `skillpay_customer/lib/models/artisan_post_model.dart`
- Create a new Dart model to parse the post data from the backend.

#### [MODIFY] `skillpay_customer/lib/models/worker_model.dart`
- Add `coverLetter` and `List<ArtisanPostModel> posts` properties.
- Update `fromMap` to parse these new fields.

#### [MODIFY] `skillpay_customer/lib/screens/artisan_profile_screen.dart`
- Update `_buildCoverLetterSection` to conditionally render the real `worker.coverLetter` (and hide the section if it's null or empty).
- Update `_buildPostsSection` to render a horizontal list or grid of the artisan's actual posts, and hide the section if `worker.posts` is empty.

## Verification Plan

### Automated Tests
- N/A

### Manual Verification
- After the backend is updated, I will seed a test post and cover letter directly into the database for the artisan `damicoledj`.
- We will hot reload the customer app to verify that the real cover letter and post appear on the profile screen.

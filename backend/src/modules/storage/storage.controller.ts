import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiConsumes,
} from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { StorageService } from './storage.service';
import { v4 as uuidv4 } from 'uuid';

@ApiTags('Storage')
@ApiBearerAuth('supabase-jwt')
@Controller('storage')
export class StorageController {
  constructor(
    private readonly storageService: StorageService,
    private readonly config: ConfigService,
  ) {}

  // Flutter: POST /storage/profile-image
  @Post('profile-image')
  @ApiOperation({ summary: 'Upload profile photo' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadProfileImage(@UploadedFile() file: Express.Multer.File) {
    return this.upload(
      file,
      this.config.get<string>('storage.bucketAvatars', 'avatars'),
      'avatars',
    );
  }

  // Flutter: POST /storage/job-image
  @Post('job-image')
  @ApiOperation({ summary: 'Upload job image' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadJobImage(@UploadedFile() file: Express.Multer.File) {
    return this.upload(
      file,
      this.config.get<string>('storage.bucketJobImages', 'job-images'),
      'jobs',
    );
  }

  // Flutter: POST /storage/chat-attachment
  @Post('chat-attachment')
  @ApiOperation({ summary: 'Upload chat attachment' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadChatAttachment(@UploadedFile() file: Express.Multer.File) {
    return this.upload(
      file,
      this.config.get<string>('storage.bucketChat', 'chat-attachments'),
      'chat',
    );
  }

  // Flutter: POST /storage/verification-document
  @Post('verification-document')
  @ApiOperation({ summary: 'Upload verification document' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async uploadDocument(@UploadedFile() file: Express.Multer.File) {
    return this.upload(
      file,
      this.config.get<string>('storage.bucketDocuments', 'verification-documents'),
      'documents',
    );
  }

  // ─── Helper ──────────────────────────────────────────────────────────────

  private async upload(
    file: Express.Multer.File,
    bucket: string,
    folder: string,
  ): Promise<{ url: string }> {
    if (!file) throw new BadRequestException('No file provided');

    const ext = file.originalname.split('.').pop() ?? 'bin';
    const path = `${folder}/${uuidv4()}.${ext}`;

    const url = await this.storageService.uploadFile(
      bucket,
      path,
      file.buffer,
      file.mimetype,
    );

    return { url };
  }
}

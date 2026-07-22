import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class StorageService {
  private readonly supabase: SupabaseClient;

  constructor(private readonly config: ConfigService) {
    this.supabase = createClient(
      this.config.get<string>('supabase.url')!,
      this.config.get<string>('supabase.serviceRoleKey')!,
    );
  }

  async uploadFile(bucketName: string, path: string, fileBuffer: Buffer, mimeType: string): Promise<string> {
    const { error } = await this.supabase.storage
      .from(bucketName)
      .upload(path, fileBuffer, {
        contentType: mimeType,
        upsert: true,
      });

    if (error) {
      throw new Error(`Storage upload failed: ${error.message}`);
    }

    const { data } = this.supabase.storage.from(bucketName).getPublicUrl(path);
    return data.publicUrl;
  }
}

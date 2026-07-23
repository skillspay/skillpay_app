import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as https from 'https';
import * as http from 'http';

@Injectable()
export class StorageService {
  private readonly supabaseUrl: string;
  private readonly serviceRoleKey: string;

  constructor(private readonly config: ConfigService) {
    this.supabaseUrl = this.config.get<string>('supabase.url')!;
    this.serviceRoleKey = this.config.get<string>('supabase.serviceRoleKey')!;
  }

  /**
   * Upload a file buffer to Supabase Storage via the REST API directly.
   * Using raw HTTPS avoids the "Invalid tenant id" bug in @supabase/supabase-js
   * when its Storage client runs inside a Node.js server environment.
   *
   * Returns the public URL of the uploaded file.
   */
  async uploadFile(
    bucketName: string,
    path: string,
    fileBuffer: Buffer,
    mimeType: string,
  ): Promise<string> {
    const uploadUrl = `${this.supabaseUrl}/storage/v1/object/${bucketName}/${path}`;

    await this._httpRequest(uploadUrl, 'POST', fileBuffer, mimeType);

    // Build the public URL (bucket must be public or have a matching policy)
    return `${this.supabaseUrl}/storage/v1/object/public/${bucketName}/${path}`;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  private _httpRequest(
    url: string,
    method: string,
    body: Buffer,
    contentType: string,
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const parsed = new URL(url);
      const options: https.RequestOptions = {
        hostname: parsed.hostname,
        port: parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
        path: parsed.pathname + parsed.search,
        method,
        headers: {
          Authorization: `Bearer ${this.serviceRoleKey}`,
          apikey: this.serviceRoleKey,
          'Content-Type': contentType,
          'Content-Length': body.length,
          'x-upsert': 'true',
        },
      };

      const transport = parsed.protocol === 'https:' ? https : http;

      const req = transport.request(options, (res) => {
        const chunks: Buffer[] = [];
        res.on('data', (chunk: Buffer) => chunks.push(chunk));
        res.on('end', () => {
          const responseBody = Buffer.concat(chunks).toString('utf-8');
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve(responseBody);
          } else {
            reject(
              new InternalServerErrorException(
                `Supabase Storage error (${res.statusCode}): ${responseBody}`,
              ),
            );
          }
        });
      });

      req.on('error', (err) => reject(new InternalServerErrorException(err.message)));
      req.write(body);
      req.end();
    });
  }
}

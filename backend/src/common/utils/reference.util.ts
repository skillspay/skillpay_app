import { v4 as uuidv4 } from 'uuid';

/**
 * Generates a unique payment/transaction reference.
 * Format: SKP-<TIMESTAMP>-<RANDOM_HEX>
 * Example: SKP-1720000000000-a3f7c2
 */
export function generateReference(prefix = 'SKP'): string {
  const timestamp = Date.now();
  const random = uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase();
  return `${prefix}-${timestamp}-${random}`;
}

import { 
  formatFileSize, 
  formatDate, 
  formatDuration, 
  parseRsyncProgress, 
  sanitizePath, 
  buildRsyncCommand,
  getDefaultSettings,
  getDefaultProfile,
  generateId,
  truncatePath 
} from '../shared/utils';

describe('Utils', () => {
  describe('formatFileSize', () => {
    it('should format bytes correctly', () => {
      expect(formatFileSize(0)).toBe('0 B');
      expect(formatFileSize(1024)).toBe('1.0 KB');
      expect(formatFileSize(1024 * 1024)).toBe('1.0 MB');
      expect(formatFileSize(1024 * 1024 * 1024)).toBe('1.0 GB');
      expect(formatFileSize(1536)).toBe('1.5 KB');
    });
  });

  describe('formatDate', () => {
    it('should format dates correctly', () => {
      const date = new Date('2023-12-25T10:30:00Z');
      const formatted = formatDate(date);
      expect(formatted).toMatch(/Dec 25, 2023/);
    });
  });

  describe('formatDuration', () => {
    it('should format durations correctly', () => {
      expect(formatDuration(30)).toBe('30s');
      expect(formatDuration(90)).toBe('1m 30s');
      expect(formatDuration(3661)).toBe('1h 1m');
    });
  });

  describe('parseRsyncProgress', () => {
    it('should parse progress2 format correctly', () => {
      const line = '1,234,567  45%  1.2MB/s    0:02:30 (xfr#1, to-chk=0/3)';
      const result = parseRsyncProgress(line);
      
      expect(result.progress).toBe(45);
      expect(result.speed).toBe('1.2 MB/s');
      expect(result.eta).toBe('2m 30s');
      expect(result.transferred).toBe('1.2 MB');
    });

    it('should handle percent-only format', () => {
      const line = '45%';
      const result = parseRsyncProgress(line);
      
      expect(result.progress).toBe(45);
    });

    it('should return empty object for invalid lines', () => {
      const line = 'some random text';
      const result = parseRsyncProgress(line);
      
      expect(result).toEqual({});
    });
  });

  describe('sanitizePath', () => {
    it('should remove dangerous characters', () => {
      expect(sanitizePath('/path/with;dangerous&chars')).toBe('/path/withdangerouschars');
      expect(sanitizePath('/safe/path')).toBe('/safe/path');
    });
  });

  describe('buildRsyncCommand', () => {
    const config = {
      user: 'testuser',
      host: 'testhost',
      port: 22,
      keyPath: '/path/to/key',
      flags: '-av --info=progress2',
      sshOptions: {
        strictHostKeyChecking: true,
        compression: false,
        serverAliveInterval: 60,
        serverAliveCountMax: 10,
      },
    };

    it('should build upload command correctly', () => {
      const command = buildRsyncCommand('upload', ['/local/file'], '/remote/path', config);
      
      expect(command[0]).toBe('rsync');
      expect(command).toContain('-av');
      expect(command).toContain('--info=progress2');
      expect(command).toContain('/local/file');
      expect(command).toContain('testuser@testhost:/remote/path');
    });

    it('should build download command correctly', () => {
      const command = buildRsyncCommand('download', ['/remote/file'], '/local/path', config);
      
      expect(command[0]).toBe('rsync');
      expect(command).toContain('testuser@testhost:/remote/file');
      expect(command).toContain('/local/path');
    });
  });

  describe('getDefaultSettings', () => {
    it('should return default settings', () => {
      const settings = getDefaultSettings();
      
      expect(settings.rsyncPath).toBe('/usr/bin/rsync');
      expect(settings.defaultFlags).toContain('-av');
      expect(settings.sshOptions.strictHostKeyChecking).toBe(true);
      expect(settings.excludePatterns).toContain('.DS_Store');
    });
  });

  describe('getDefaultProfile', () => {
    it('should return default profile', () => {
      const profile = getDefaultProfile();
      
      expect(profile.name).toBe('New Profile');
      expect(profile.port).toBe(22);
      expect(profile.remotePath).toBe('/home');
    });
  });

  describe('generateId', () => {
    it('should generate unique IDs', () => {
      const id1 = generateId();
      const id2 = generateId();
      
      expect(id1).not.toBe(id2);
      expect(typeof id1).toBe('string');
      expect(id1.length).toBeGreaterThan(0);
    });
  });

  describe('truncatePath', () => {
    it('should truncate long paths', () => {
      const longPath = '/very/long/path/that/exceeds/maximum/length/and/should/be/truncated';
      const truncated = truncatePath(longPath, 30);
      
      expect(truncated.length).toBeLessThanOrEqual(30);
      expect(truncated).toContain('...');
    });

    it('should not truncate short paths', () => {
      const shortPath = '/short/path';
      const result = truncatePath(shortPath, 30);
      
      expect(result).toBe(shortPath);
    });
  });
});

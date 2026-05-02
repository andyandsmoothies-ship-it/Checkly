namespace Checkly.Api.Common;

/// <summary>
/// Shared magic byte validation for uploaded image files.
/// Centralizes format checks so adding a new format (e.g., AVIF) requires one change.
/// </summary>
public static class ImageValidation
{
    /// <summary>
    /// Returns true if the first bytes of the file header match a supported image format.
    /// Supports: JPEG, PNG, WebP, HEIC.
    /// </summary>
    public static bool IsValidImageMagicBytes(byte[] header, int bytesRead)
    {
        if (bytesRead < 3) return false;

        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) return true;

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (bytesRead >= 8 &&
            header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
            header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
            return true;

        // WebP: RIFF at [0-3] and WEBP at [8-11]
        if (bytesRead >= 12 &&
            header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
            header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
            return true;

        // HEIC: "ftyp" ASCII at offset 4
        if (bytesRead >= 8 &&
            header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70)
            return true;

        return false;
    }
}

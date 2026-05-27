package com.vortexsynergy.backend.service;

import com.vortexsynergy.backend.exception.BadRequestException;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class FileStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp");
    private static final List<String> ALLOWED_CONTENT_TYPES = List.of(
        "image/jpeg",
        "image/png",
        "image/webp"
    );

    @Value("${app.storage.upload-dir}")
    private String uploadDir;

    public String storeResourcePhoto(MultipartFile file) {
        if (file.isEmpty()) {
            throw new BadRequestException("Image file is required");
        }
        if (!ALLOWED_CONTENT_TYPES.contains(file.getContentType())) {
            throw new BadRequestException("Only JPG, PNG, and WEBP images are allowed");
        }

        String originalFilename = file.getOriginalFilename() == null ? "photo" : file.getOriginalFilename();
        String extension = extractExtension(originalFilename);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new BadRequestException("Unsupported image extension");
        }

        try {
            Path directory = Path.of(uploadDir, "resource-photos");
            Files.createDirectories(directory);

            String filename = UUID.randomUUID() + "." + extension;
            Path destination = directory.resolve(filename);
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, destination, StandardCopyOption.REPLACE_EXISTING);
            }

            return "/uploads/resource-photos/" + filename;
        } catch (IOException exception) {
            throw new BadRequestException("Failed to store uploaded image");
        }
    }

    private String extractExtension(String filename) {
        int separator = filename.lastIndexOf('.');
        if (separator < 0 || separator == filename.length() - 1) {
            return "";
        }
        return filename.substring(separator + 1).toLowerCase(Locale.ROOT);
    }
}

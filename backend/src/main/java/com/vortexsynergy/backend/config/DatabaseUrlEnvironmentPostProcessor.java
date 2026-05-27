package com.vortexsynergy.backend.config;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

/**
 * Accepts provider-style PostgreSQL URLs such as
 * postgresql://user:pass@host:5432/db and exposes equivalent Spring datasource
 * properties before auto-configuration runs.
 */
public class DatabaseUrlEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    private static final String PROPERTY_SOURCE_NAME = "providerDatabaseUrl";

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String directDbUrl = trimToNull(environment.getProperty("DB_URL"));
        if (directDbUrl != null && directDbUrl.startsWith("jdbc:")) {
            return;
        }

        String providerUrl = directDbUrl != null ? directDbUrl : trimToNull(environment.getProperty("DATABASE_URL"));
        if (providerUrl == null) {
            return;
        }

        if (!(providerUrl.startsWith("postgres://") || providerUrl.startsWith("postgresql://"))) {
            return;
        }

        URI uri;
        try {
            uri = URI.create(providerUrl);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException("Unable to parse provider database URL", exception);
        }

        String host = trimToNull(uri.getHost());
        String database = trimToNull(uri.getPath() == null ? null : uri.getPath().replaceFirst("^/", ""));
        if (host == null || database == null) {
            throw new IllegalStateException("Provider database URL is missing host or database name");
        }

        StringBuilder jdbcUrl = new StringBuilder("jdbc:postgresql://").append(host);
        if (uri.getPort() > 0) {
            jdbcUrl.append(':').append(uri.getPort());
        }
        jdbcUrl.append('/').append(database);
        if (trimToNull(uri.getRawQuery()) != null) {
            jdbcUrl.append('?').append(uri.getRawQuery());
        }

        Map<String, Object> overrides = new LinkedHashMap<>();
        overrides.put("spring.datasource.url", jdbcUrl.toString());

        if (trimToNull(environment.getProperty("spring.datasource.username")) == null
            && trimToNull(environment.getProperty("DB_USERNAME")) == null) {
            String username = decodeUserInfoPart(uri.getRawUserInfo(), 0);
            if (username != null) {
                overrides.put("spring.datasource.username", username);
            }
        }

        if (trimToNull(environment.getProperty("spring.datasource.password")) == null
            && trimToNull(environment.getProperty("DB_PASSWORD")) == null) {
            String password = decodeUserInfoPart(uri.getRawUserInfo(), 1);
            if (password != null) {
                overrides.put("spring.datasource.password", password);
            }
        }

        environment.getPropertySources().addFirst(new MapPropertySource(PROPERTY_SOURCE_NAME, overrides));
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }

    private String decodeUserInfoPart(String rawUserInfo, int index) {
        String userInfo = trimToNull(rawUserInfo);
        if (userInfo == null) {
            return null;
        }
        String[] parts = userInfo.split(":", 2);
        if (index >= parts.length) {
            return null;
        }
        return URLDecoder.decode(parts[index], StandardCharsets.UTF_8);
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}

package com.example.demo.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration corsConfig = new CorsConfiguration();
        
        // Autoriser toutes les origines même avec credentials
        corsConfig.setAllowedOriginPatterns(List.of("*")); 
        
        // Autoriser toutes les méthodes HTTP
        corsConfig.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        
        // Autoriser tous les headers
        corsConfig.setAllowedHeaders(List.of("*"));
        
        // Autoriser l'envoi de cookies, tokens d'authentification, etc.
        corsConfig.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfig);
        
        return new CorsFilter(source);
    }
}

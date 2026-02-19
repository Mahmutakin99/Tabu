#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'set'

TARGET_CATEGORIES = [
  'Diziler & Filmler',
  'Astronomi, Fizik & Mühendislik',
  'Spor',
  'Tarih',
  'Coğrafya',
  'Müzik',
  'Teknoloji',
  'Yemek',
  'Doğa',
  'Sanat'
].freeze

TARGET_MIN_COUNT = 450
TARGET_MAX_COUNT = 500
DIFFICULTIES = %w[easy medium hard].freeze
MAX_WORD_LENGTH = 64
MAX_TOKEN_COUNT = 9
DIFFICULTY_RATIO_RANGES = {
  'easy' => (0.25..0.45),
  'medium' => (0.35..0.55),
  'hard' => (0.10..0.30)
}.freeze

GENERIC_BANNED = [
  'temel',
  'gelişmiş',
  'profesyonel',
  'yeni nesil'
].freeze

SENSITIVE_TERMS = [
  'porn',
  'porno',
  'pornographic',
  'sexual',
  'sex',
  'nude',
  'whore',
  'erotic',
  'shit'
].freeze

def normalize_text(text)
  text
    .to_s
    .unicode_normalize(:nfkc)
    .downcase
    .gsub(/[^\p{Alnum}\s]/u, ' ')
    .gsub(/\s+/, ' ')
    .strip
rescue StandardError
  text.to_s.downcase.gsub(/[^[:alnum:]\s]/, ' ').gsub(/\s+/, ' ').strip
end

def contains_banned_generic?(text)
  normalized = normalize_text(text)
  GENERIC_BANNED.any? do |needle|
    n = normalize_text(needle)
    normalized == n || normalized.start_with?("#{n} ") || normalized.end_with?(" #{n}") || normalized.include?(" #{n} ")
  end
end

def fail_with(errors)
  warn 'Katalog doğrulaması başarısız.'
  errors.first(120).each { |error| warn "- #{error}" }
  warn "Toplam hata: #{errors.length}" if errors.length > 120
  exit(1)
end

def token_count(text)
  text.to_s.scan(/\p{L}[\p{L}\p{Mn}\p{Pd}]*/u).length
end

def contains_sensitive?(text)
  normalized = normalize_text(text)
  SENSITIVE_TERMS.any? do |token|
    normalized == token ||
      normalized.start_with?("#{token} ") ||
      normalized.end_with?(" #{token}") ||
      normalized.include?(" #{token} ")
  end
end

path = ARGV[0] || File.expand_path('../Tabu/Files/Kelimeler.json', __dir__)
catalog = JSON.parse(File.read(path))
errors = []

unless catalog.is_a?(Hash)
  fail_with(['JSON kökü bir nesne (hash) olmalı.'])
end

missing_categories = TARGET_CATEGORIES - catalog.keys
extra_categories = catalog.keys - TARGET_CATEGORIES
errors << "Eksik kategoriler: #{missing_categories.join(', ')}" if missing_categories.any?
errors << "Fazla kategoriler: #{extra_categories.join(', ')}" if extra_categories.any?

global_seen = Set.new

TARGET_CATEGORIES.each do |category|
  entries = catalog[category]
  unless entries.is_a?(Array)
    errors << "#{category}: kategori değeri dizi olmalı."
    next
  end

  if entries.length < TARGET_MIN_COUNT || entries.length > TARGET_MAX_COUNT
    errors << "#{category}: kart sayısı #{entries.length}, beklenen aralık #{TARGET_MIN_COUNT}-#{TARGET_MAX_COUNT}."
  end

  local_seen = Set.new
  difficulty_counts = Hash.new(0)

  entries.each_with_index do |entry, index|
    unless entry.is_a?(Hash)
      errors << "#{category}[#{index}]: kart nesne olmalı."
      next
    end

    word = entry['Kelime']
    if !word.is_a?(String) || word.strip.empty?
      errors << "#{category}[#{index}]: Kelime boş veya geçersiz."
      next
    end

    if contains_banned_generic?(word)
      errors << "#{category}[#{index}] '#{word}': yasaklı jenerik ifade içeriyor."
    end
    if word.length > MAX_WORD_LENGTH
      errors << "#{category}[#{index}] '#{word}': kelime uzunluğu #{word.length}, max #{MAX_WORD_LENGTH}."
    end
    if token_count(word) > MAX_TOKEN_COUNT
      errors << "#{category}[#{index}] '#{word}': token sayısı çok yüksek."
    end

    normalized_word = normalize_text(word)
    if contains_sensitive?(word)
      errors << "#{category}[#{index}] '#{word}': hassas/uygunsuz içerik içeriyor."
    end
    if local_seen.include?(normalized_word)
      errors << "#{category}[#{index}] '#{word}': kategori içinde tekrar ediyor."
    else
      local_seen << normalized_word
    end

    if global_seen.include?(normalized_word)
      errors << "#{category}[#{index}] '#{word}': global tekrar ediyor."
    else
      global_seen << normalized_word
    end

    forbidden = entry['Yasaklılar']
    if !forbidden.is_a?(Array)
      errors << "#{category}[#{index}] '#{word}': Yasaklılar dizi olmalı."
    elsif forbidden.length != 5
      errors << "#{category}[#{index}] '#{word}': Yasaklı sayısı #{forbidden.length}, beklenen 5."
    else
      used = Set.new
      forbidden.each_with_index do |f, fidx|
        if !f.is_a?(String) || f.strip.empty?
          errors << "#{category}[#{index}] '#{word}': Yasaklı[#{fidx}] boş/geçersiz."
          next
        end

        if contains_banned_generic?(f)
          errors << "#{category}[#{index}] '#{word}': Yasaklı '#{f}' jenerik ifade içeriyor."
        end

        nf = normalize_text(f)
        if contains_sensitive?(f)
          errors << "#{category}[#{index}] '#{word}': Yasaklı '#{f}' hassas/uygunsuz içerik içeriyor."
        end
        if nf == normalized_word
          errors << "#{category}[#{index}] '#{word}': yasaklı kelimeyle aynı."
        end

        if used.include?(nf)
          errors << "#{category}[#{index}] '#{word}': yasaklı tekrar '#{f}'."
        else
          used << nf
        end
      end
    end

    difficulty = entry['Zorluk']
    unless DIFFICULTIES.include?(difficulty)
      errors << "#{category}[#{index}] '#{word}': Zorluk '#{difficulty}' geçersiz."
    else
      difficulty_counts[difficulty] += 1
    end
  end
  
  if entries.any?
    DIFFICULTY_RATIO_RANGES.each do |difficulty, ratio_range|
      ratio = difficulty_counts[difficulty].to_f / entries.length.to_f
      unless ratio_range.cover?(ratio)
        ratio_percent = (ratio * 100.0).round(2)
        min_percent = (ratio_range.begin * 100.0).round(1)
        max_percent = (ratio_range.end * 100.0).round(1)
        errors << "#{category}: '#{difficulty}' oranı %#{ratio_percent}, beklenen aralık %#{min_percent}-#{max_percent}."
      end
    end
  end
end

fail_with(errors) if errors.any?

puts 'Katalog doğrulaması başarılı.'
puts "Dosya: #{path}"
puts "Kategori sayısı: #{catalog.keys.length}"
puts "Toplam kart: #{catalog.values.sum(&:length)}"
TARGET_CATEGORIES.each do |category|
  counts = Hash.new(0)
  catalog[category].each { |entry| counts[entry['Zorluk']] += 1 }
  puts "- #{category}: #{catalog[category].length} (easy=#{counts['easy']}, medium=#{counts['medium']}, hard=#{counts['hard']})"
end

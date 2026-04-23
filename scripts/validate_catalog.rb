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

EXPECTED_COUNT_PER_CATEGORY = 500
DIFFICULTIES = %w[easy medium hard].freeze
DIFFICULTY_RATIO_RANGES = {
  'easy' => (0.25..0.45),
  'medium' => (0.35..0.55),
  'hard' => (0.10..0.30)
}.freeze

GENERIC_BANNED_TERMS = ['temel', 'gelişmiş', 'profesyonel', 'yeni nesil'].freeze

CATEGORY_CORE_TERMS = {
  'Diziler & Filmler' => %w[film dizi oyuncu yönetmen karakter sahne senaryo kamera kurgu],
  'Astronomi, Fizik & Mühendislik' => %w[uzay yıldız gezegen fizik mühendislik enerji deney kuvvet teori],
  'Spor' => %w[spor maç takım skor oyuncu turnuva antrenman saha hakem],
  'Tarih' => %w[tarih savaş antlaşma imparatorluk medeniyet dönem olay kronoloji belge],
  'Coğrafya' => %w[coğrafya kıta ülke şehir dağ nehir ada iklim harita],
  'Müzik' => %w[müzik ritim melodi nota enstrüman konser albüm şarkı sanatçı],
  'Teknoloji' => %w[teknoloji yazılım donanım sistem ağ veri cihaz uygulama algoritma],
  'Yemek' => %w[yemek tarif mutfak malzeme lezzet baharat sos pişirme tat],
  'Doğa' => %w[doğa orman canlı bitki hayvan ekosistem habitat çevre iklim],
  'Sanat' => %w[sanat eser galeri sergi müze kompozisyon estetik resim heykel]
}.freeze

STOPWORDS = Set.new(%w[
  ve ile ya da de da bu şu o bir için gibi kadar en çok az daha
  the of and in on at to by from an a into under over
]).freeze

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

def significant_tokens(text)
  text.to_s.scan(/\p{L}[\p{L}\p{Mn}\p{Pd}]*/u)
      .map(&:strip)
      .reject(&:empty?)
      .reject do |token|
        normalized = normalize_text(token)
        normalized.empty? || STOPWORDS.include?(normalized) || normalized.length < 2
      end
end

def contains_banned_generic?(text)
  normalized = normalize_text(text)
  GENERIC_BANNED_TERMS.any? do |needle|
    n = normalize_text(needle)
    normalized == n ||
      normalized.start_with?("#{n} ") ||
      normalized.end_with?(" #{n}") ||
      normalized.include?(" #{n} ")
  end
end

def matches_word_relevance?(forbidden_normalized, word_tokens)
  forbidden_normalized.any? do |forbidden|
    word_tokens.any? do |token|
      forbidden == token || forbidden.include?(token) || token.include?(forbidden)
    end
  end
end

def fail_with(errors)
  warn 'Katalog doğrulaması başarısız.'
  errors.first(120).each { |error| warn "- #{error}" }
  warn "Toplam hata: #{errors.length}" if errors.length > 120
  exit(1)
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

global_seen_words = Set.new

TARGET_CATEGORIES.each do |category|
  entries = catalog[category]
  unless entries.is_a?(Array)
    errors << "#{category}: kategori değeri dizi olmalı."
    next
  end

  if entries.length != EXPECTED_COUNT_PER_CATEGORY
    errors << "#{category}: kart sayısı #{entries.length}, beklenen #{EXPECTED_COUNT_PER_CATEGORY}."
  end

  difficulty_counts = Hash.new(0)
  local_seen_words = Set.new
  category_terms = CATEGORY_CORE_TERMS.fetch(category).map { |term| normalize_text(term) }.to_set

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

    normalized_word = normalize_text(word)
    if normalized_word.empty?
      errors << "#{category}[#{index}] '#{word}': normalize sonrası boş."
      next
    end

    if local_seen_words.include?(normalized_word)
      errors << "#{category}[#{index}] '#{word}': kategori içinde tekrar ediyor."
    else
      local_seen_words << normalized_word
    end

    if global_seen_words.include?(normalized_word)
      errors << "#{category}[#{index}] '#{word}': global tekrar ediyor."
    else
      global_seen_words << normalized_word
    end

    source_id = entry['KaynakID']
    unless source_id.is_a?(String) && source_id.match?(/\A[QL]\d+(?:-S\d+)?\z/)
      errors << "#{category}[#{index}] '#{word}': KaynakID '#{source_id}' geçersiz (Q... veya L... olmalı)."
    end

    forbidden = entry['Yasaklılar']
    if !forbidden.is_a?(Array)
      errors << "#{category}[#{index}] '#{word}': Yasaklılar dizi olmalı."
    elsif forbidden.length != 5
      errors << "#{category}[#{index}] '#{word}': Yasaklı sayısı #{forbidden.length}, beklenen 5."
    else
      forbidden_seen = Set.new
      forbidden_normalized = []

      forbidden.each_with_index do |item, forbidden_index|
        if !item.is_a?(String) || item.strip.empty?
          errors << "#{category}[#{index}] '#{word}': Yasaklı[#{forbidden_index}] boş/geçersiz."
          next
        end

        normalized_forbidden = normalize_text(item)
        if normalized_forbidden.empty?
          errors << "#{category}[#{index}] '#{word}': Yasaklı '#{item}' normalize sonrası boş."
          next
        end

        if contains_banned_generic?(item)
          errors << "#{category}[#{index}] '#{word}': Yasaklı '#{item}' jenerik ifade içeriyor."
        end

        if normalized_forbidden == normalized_word
          errors << "#{category}[#{index}] '#{word}': yasaklı kelimeyle aynı."
        end

        if forbidden_seen.include?(normalized_forbidden)
          errors << "#{category}[#{index}] '#{word}': yasaklı tekrar '#{item}'."
        else
          forbidden_seen << normalized_forbidden
          forbidden_normalized << normalized_forbidden
        end
      end

      word_terms = significant_tokens(word).map { |token| normalize_text(token) }.to_set
      if word_terms.empty?
        word_terms = normalize_text(word).split.to_set
      end

      has_word_link = matches_word_relevance?(forbidden_normalized, word_terms)
      requires_word_link = word_terms.any? { |token| token.length > 1 }
      has_category_link = forbidden_normalized.any? { |value| category_terms.include?(value) }

      if requires_word_link && has_word_link == false
        errors << "#{category}[#{index}] '#{word}': yasaklılar kelimeyle ilişkili görünmüyor."
      end

      unless has_category_link
        errors << "#{category}[#{index}] '#{word}': yasaklılar kategori çekirdek terimi içermiyor."
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
      next if ratio_range.cover?(ratio)

      ratio_percent = (ratio * 100.0).round(2)
      min_percent = (ratio_range.begin * 100.0).round(2)
      max_percent = (ratio_range.end * 100.0).round(2)
      errors << "#{category}: '#{difficulty}' oranı %#{ratio_percent}, beklenen aralık %#{min_percent}-#{max_percent}."
    end
  end
end

fail_with(errors) if errors.any?

puts 'Katalog doğrulaması başarılı.'
puts "Dosya: #{path}"
puts "Kategori sayısı: #{catalog.keys.length}"
puts "Toplam kart: #{catalog.values.sum(&:length)}"
TARGET_CATEGORIES.each do |category|
  entries = catalog[category]
  counts = entries.each_with_object(Hash.new(0)) { |entry, memo| memo[entry['Zorluk']] += 1 }
  puts "- #{category}: #{entries.length} (easy=#{counts['easy']}, medium=#{counts['medium']}, hard=#{counts['hard']})"
end

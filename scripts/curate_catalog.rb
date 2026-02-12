#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'set'

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
  'shit',
  'fuck'
].freeze

CATEGORY_TERMS = {
  'Diziler & Filmler' => %w[film dizi oyuncu yönetmen sahne karakter senaryo kamera kurgu]
    .freeze,
  'Astronomi, Fizik & Mühendislik' => %w[uzay yıldız gezegen fizik mühendislik deney enerji kuvvet teori]
    .freeze,
  'Spor' => %w[spor maç takım skor antrenman turnuva saha oyuncu hakem]
    .freeze,
  'Tarih' => %w[tarih dönem savaş antlaşma imparatorluk medeniyet olay kronoloji kaynak]
    .freeze,
  'Coğrafya' => %w[coğrafya kıta ülke şehir dağ nehir ada iklim harita]
    .freeze,
  'Müzik' => %w[müzik ritim melodi nota enstrüman konser albüm şarkı sanatçı]
    .freeze,
  'Teknoloji' => %w[teknoloji yazılım donanım sistem ağ veri cihaz uygulama algoritma]
    .freeze,
  'Yemek' => %w[yemek mutfak tarif malzeme lezzet baharat sos pişirme tat]
    .freeze,
  'Doğa' => %w[doğa orman canlı bitki hayvan ekosistem iklim çevre habitat]
    .freeze,
  'Sanat' => %w[sanat eser galeri sergi müze kompozisyon estetik resim heykel]
    .freeze
}.freeze

TARGET_PER_CATEGORY = 500
MAX_WORD_LENGTH = 64
MAX_TOKEN_COUNT = 9

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

def contains_generic?(text)
  normalized = normalize_text(text)
  GENERIC_BANNED.any? do |token|
    n = normalize_text(token)
    normalized == n || normalized.start_with?("#{n} ") || normalized.end_with?(" #{n}") || normalized.include?(" #{n} ")
  end
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

def significant_tokens(text)
  text.to_s.scan(/\p{L}[\p{L}\p{Mn}\p{Pd}]*/u)
      .map(&:strip)
      .reject(&:empty?)
end

def valid_word?(word)
  return false if word.nil?

  trimmed = word.strip
  return false if trimmed.empty?
  return false if trimmed.length > MAX_WORD_LENGTH
  return false if contains_generic?(trimmed)
  return false if contains_sensitive?(trimmed)

  tokens = significant_tokens(trimmed)
  return false if tokens.empty?
  return false if tokens.length > MAX_TOKEN_COUNT

  true
end

def sanitize_forbidden_words(word, raw_forbidden, category)
  normalized_word = normalize_text(word)
  pool = []

  pool.concat(raw_forbidden)
  pool.concat(significant_tokens(word).first(3))
  pool.concat(CATEGORY_TERMS.fetch(category, []))

  used = Set.new
  result = []

  pool.each do |candidate|
    text = candidate.to_s.strip
    normalized = normalize_text(text)
    next if text.empty? || normalized.empty?
    next if normalized == normalized_word
    next if contains_generic?(text)
    next if contains_sensitive?(text)
    next if used.include?(normalized)

    used << normalized
    result << text
    break if result.length == 5
  end

  # If there are still missing slots, add deterministic category fallbacks.
  CATEGORY_TERMS.fetch(category, []).each do |fallback|
    break if result.length == 5

    normalized = normalize_text(fallback)
    next if normalized == normalized_word || used.include?(normalized)

    used << normalized
    result << fallback
  end

  result.first(5)
end

def fallback_difficulty(word)
  normalized = normalize_text(word)
  token_count = significant_tokens(word).length
  score = normalized.length + token_count * 6

  if score < 22
    'easy'
  elsif score < 34
    'medium'
  else
    'hard'
  end
end

input_path = ARGV[0] || File.expand_path('../Tabu/Files/Kelimeler.json', __dir__)
output_path = ARGV[1] || input_path

catalog = JSON.parse(File.read(input_path))

unless catalog.is_a?(Hash)
  warn 'Katalog kökü hash olmalı.'
  exit(1)
end

cleaned = {}
global_seen = Set.new

catalog.each do |category, entries|
  next unless entries.is_a?(Array)

  cleaned_entries = []
  local_seen = Set.new

  entries.each do |entry|
    break if cleaned_entries.length >= TARGET_PER_CATEGORY
    next unless entry.is_a?(Hash)

    word = entry['Kelime'].to_s.strip
    next unless valid_word?(word)

    normalized_word = normalize_text(word)
    next if normalized_word.empty?
    next if local_seen.include?(normalized_word)
    next if global_seen.include?(normalized_word)

    forbidden = sanitize_forbidden_words(word, entry['Yasaklılar'] || [], category)
    next if forbidden.length < 5

    difficulty = entry['Zorluk'].to_s.downcase
    difficulty = fallback_difficulty(word) unless %w[easy medium hard].include?(difficulty)

    cleaned_entries << {
      'Kelime' => word,
      'Yasaklılar' => forbidden,
      'Zorluk' => difficulty
    }

    local_seen << normalized_word
    global_seen << normalized_word
  end

  cleaned[category] = cleaned_entries
end

File.write(output_path, JSON.pretty_generate(cleaned))

puts "Katalog düzenlendi: #{output_path}"
puts "Kategori sayısı: #{cleaned.keys.length}"
puts "Toplam kart: #{cleaned.values.sum(&:length)}"
cleaned.each do |category, entries|
  difficulty_counts = entries.each_with_object(Hash.new(0)) { |item, memo| memo[item['Zorluk']] += 1 }
  puts "- #{category}: #{entries.length} (easy=#{difficulty_counts['easy']}, medium=#{difficulty_counts['medium']}, hard=#{difficulty_counts['hard']})"
end

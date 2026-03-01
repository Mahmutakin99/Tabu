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

TARGET_COUNT_PER_CATEGORY = 500
MAX_WORD_LENGTH = 160
MAX_TOKEN_COUNT = 24

DIFFICULTY_RATIOS = {
  'easy' => 0.35,
  'medium' => 0.45,
  'hard' => 0.20
}.freeze

GENERIC_BANNED_TERMS = ['temel', 'gelişmiş', 'profesyonel', 'yeni nesil'].freeze
SENSITIVE_BANNED_TERMS = %w[porn porno pornographic sexual sex nude whore erotic fuck shit].freeze
BANNED_TOKEN_SET = Set.new(GENERIC_BANNED_TERMS + SENSITIVE_BANNED_TERMS).freeze

STOPWORDS = Set.new(%w[
  ve ile ya da de da bu şu o bir için gibi kadar en çok az daha
  the of and in on at to by from an a into under over
]).freeze

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

CATEGORY_CONTEXT_TERMS = {
  'Diziler & Filmler' => %w[yapım tür senaryo çekim kurgu],
  'Astronomi, Fizik & Mühendislik' => %w[ölçüm teori araştırma denklem laboratuvar],
  'Spor' => %w[müsabaka organizasyon performans puan kural],
  'Tarih' => %w[kaynak dönem olay kronoloji belge],
  'Coğrafya' => %w[bölge konum topoğrafya sınır harita],
  'Müzik' => %w[besteci yorum kayıt repertuvar performans],
  'Teknoloji' => %w[sistem platform mühendislik geliştirme ürün],
  'Yemek' => %w[malzeme tarif mutfak sunum lezzet],
  'Doğa' => %w[ekosistem habitat çevre canlı yaşam],
  'Sanat' => %w[akım teknik kompozisyon üslup estetik]
}.freeze

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

def normalize_token(token)
  normalize_text(token).gsub(' ', '')
end

def human_tokens(text)
  text.to_s.scan(/\p{L}[\p{L}\p{Mn}\p{Pd}]*/u).map(&:strip).reject(&:empty?)
end

def significant_tokens(text)
  human_tokens(text).reject do |token|
    normalized = normalize_text(token)
    normalized.empty? || STOPWORDS.include?(normalized) || normalized.length < 2
  end
end

def extract_source_id(raw_value)
  value = raw_value.to_s.strip
  return nil if value.empty?

  if (match = value.match(/[QL]\d+(?:-S\d+)?/i))
    match[0].upcase
  else
    nil
  end
end

def strip_banned_tokens(text)
  tokens = text.to_s.split(/\s+/)
  filtered = tokens.reject { |token| BANNED_TOKEN_SET.include?(normalize_token(token)) }
  filtered.join(' ')
end

def constrain_word(text)
  value = text.to_s.gsub(/\s+/, ' ').strip
  tokens = value.split(/\s+/)
  if tokens.length > MAX_TOKEN_COUNT
    value = tokens.first(MAX_TOKEN_COUNT).join(' ')
  end

  return value if value.length <= MAX_WORD_LENGTH

  while value.length > MAX_WORD_LENGTH && value.include?(' ')
    value = value.split(/\s+/)[0...-1].join(' ')
  end

  value = value[0, MAX_WORD_LENGTH] if value.length > MAX_WORD_LENGTH
  value.strip
end

def clean_label(raw)
  value = raw.to_s.strip
  value = value.gsub(/\s*\([^)]*\)\s*$/, '')
  value = value.gsub(/\s+/, ' ').strip
  stripped = strip_banned_tokens(value)
  stripped = stripped.gsub(/\s+/, ' ').strip
  value = stripped unless stripped.empty?
  constrain_word(value)
end

def unique_word_for(raw_word:, source_id:, global_seen:)
  candidates = []
  cleaned = clean_label(raw_word)
  candidates << cleaned unless cleaned.empty?

  original_constrained = constrain_word(raw_word.to_s.gsub(/\s+/, ' ').strip)
  candidates << original_constrained unless original_constrained.empty?

  fallback = [cleaned, source_id].reject(&:empty?).join(' ')
  fallback = constrain_word(fallback)
  candidates << fallback unless fallback.empty?

  candidates.each do |candidate|
    normalized = normalize_text(candidate)
    next if normalized.empty? || global_seen.include?(normalized)

    return candidate
  end

  nil
end

def complexity_score(word)
  normalized = normalize_text(word)
  tokens = significant_tokens(word)
  score = normalized.length
  score += tokens.length * 6
  score += 8 if normalized.include?(' ')
  score += 4 if word.include?(':')
  score += 4 if word.include?('-')
  score
end

def assign_difficulties!(entries)
  total = entries.length
  easy_count = (total * DIFFICULTY_RATIOS.fetch('easy')).round
  medium_count = (total * DIFFICULTY_RATIOS.fetch('medium')).round
  hard_count = total - easy_count - medium_count

  ranked_indices = entries.each_with_index
                         .map { |entry, idx| [idx, complexity_score(entry['Kelime'])] }
                         .sort_by { |(_, score)| score }

  easy_cut = easy_count
  medium_cut = easy_count + medium_count

  ranked_indices.each_with_index do |(entry_index, _), rank|
    difficulty = if rank < easy_cut
                   'easy'
                 elsif rank < medium_cut
                   'medium'
                 else
                   'hard'
                 end
    entries[entry_index]['Zorluk'] = difficulty
  end

  counts = entries.each_with_object(Hash.new(0)) { |entry, memo| memo[entry['Zorluk']] += 1 }
  expected = {
    'easy' => easy_count,
    'medium' => medium_count,
    'hard' => hard_count
  }

  return if counts == expected

  raise "Difficulty dağılımı beklenenle uyuşmuyor: beklenen=#{expected}, gerçek=#{counts}"
end

def build_forbidden_words(word:, category:, index:)
  normalized_word = normalize_text(word)
  word_terms = significant_tokens(word)
  fallback_word_terms = human_tokens(word)
  alias_terms = word_terms.map do |token|
    next if token.length < 5

    alias_length = [token.length / 2, 4].max
    token[0, alias_length]
  end.compact

  category_terms = CATEGORY_CORE_TERMS.fetch(category)
  context_terms = CATEGORY_CONTEXT_TERMS.fetch(category)

  pool = []
  pool.concat(alias_terms.first(2))
  pool.concat(word_terms.first(3))
  pool.concat(fallback_word_terms.first(2))

  pool << category_terms[index % category_terms.length]
  pool << category_terms[(index + 3) % category_terms.length]
  pool << context_terms[index % context_terms.length]

  pool.concat(category_terms)
  pool.concat(context_terms)
  pool.concat(word_terms)

  forbidden = []
  used = Set.new

  pool.each do |candidate|
    text = candidate.to_s.strip
    normalized = normalize_text(text)

    next if text.empty? || normalized.empty?
    next if normalized == normalized_word
    next if used.include?(normalized)

    used << normalized
    forbidden << text
    break if forbidden.length == 5
  end

  if forbidden.length < 5
    raise "Yasaklı üretilemedi: category=#{category}, word='#{word}', count=#{forbidden.length}'"
  end

  forbidden
end

def fail_with(message)
  warn message
  exit(1)
end

output_path = ARGV[0] || File.expand_path('../Tabu/Files/Kelimeler.json', __dir__)
sources_path = ARGV[1] || File.expand_path('../Tabu/Files/Kelimeler.sources.json', __dir__)

sources = JSON.parse(File.read(sources_path))
source_items = sources['items']

fail_with("Kaynak dosyada 'items' bulunamadı: #{sources_path}") unless source_items.is_a?(Hash)

missing_categories = TARGET_CATEGORIES - source_items.keys
extra_categories = source_items.keys - TARGET_CATEGORIES

fail_with("Kaynak dosyada eksik kategoriler: #{missing_categories.join(', ')}") if missing_categories.any?
fail_with("Kaynak dosyada fazla kategoriler: #{extra_categories.join(', ')}") if extra_categories.any?

catalog = {}
global_seen = Set.new

TARGET_CATEGORIES.each do |category|
  raw_entries = source_items.fetch(category)
  fail_with("Kategori dizi değil: #{category}") unless raw_entries.is_a?(Array)

  prepared = []

  raw_entries.each_with_index do |item, index|
    break if prepared.length >= TARGET_COUNT_PER_CATEGORY
    next unless item.is_a?(Hash)

    source_id = extract_source_id(item['Wikidata'])
    next if source_id.nil?

    unique_word = unique_word_for(raw_word: item['Kelime'], source_id: source_id, global_seen: global_seen)
    next if unique_word.nil?

    normalized_word = normalize_text(unique_word)
    next if normalized_word.empty?

    forbidden = build_forbidden_words(word: unique_word, category: category, index: index)

    prepared << {
      'Kelime' => unique_word,
      'Yasaklılar' => forbidden,
      'Zorluk' => 'medium',
      'KaynakID' => source_id
    }

    global_seen << normalized_word
  end

  if prepared.length != TARGET_COUNT_PER_CATEGORY
    fail_with("Kategori için #{TARGET_COUNT_PER_CATEGORY} kart üretilemedi: #{category} (#{prepared.length})")
  end

  assign_difficulties!(prepared)
  catalog[category] = prepared
end

File.write(output_path, JSON.pretty_generate(catalog))

puts "Katalog yeniden oluşturuldu: #{output_path}"
puts "Kaynak manifest: #{sources_path}"
puts "Toplam kart: #{catalog.values.sum(&:length)}"
TARGET_CATEGORIES.each do |category|
  entries = catalog.fetch(category)
  counts = entries.each_with_object(Hash.new(0)) { |entry, memo| memo[entry['Zorluk']] += 1 }
  puts "- #{category}: #{entries.length} (easy=#{counts['easy']}, medium=#{counts['medium']}, hard=#{counts['hard']})"
end

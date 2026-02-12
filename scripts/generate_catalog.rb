#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'set'
require 'open3'
require 'time'

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

TARGET_COUNT = 500
MAX_WORD_LENGTH = 48
MAX_TOKEN_COUNT = 6

GENERIC_BANNED = [
  'temel',
  'gelişmiş',
  'profesyonel',
  'yeni nesil'
].freeze

SENSITIVE_TERMS = [
  'sexual',
  'abuse',
  'massacre',
  'murder',
  'rape',
  'porn',
  'porno',
  'suicide',
  'terror',
  'genocide',
  'shit'
].freeze

STOPWORDS = Set.new(%w[
  ve ile ya da de da bir bu şu o için gibi kadar en çok az daha
  the of and in on at to by from an a
  ile ilgili hakkında üzerine için the a an
  for that this with without between into over under it its is are was were
]).freeze

CATEGORY_TERMS = {
  'Diziler & Filmler' => %w[film dizi oyuncu yönetmen sahne karakter sezon fragman set kurgu],
  'Astronomi, Fizik & Mühendislik' => %w[uzay yıldız gezegen fizik mühendislik enerji kuvvet deney denklem teori],
  'Spor' => %w[spor maç takım skor turnuva antrenman taktik saha oyuncu şampiyon],
  'Tarih' => %w[tarih savaş antlaşma imparatorluk devrim hanedan kronoloji medeniyet dönem belge],
  'Coğrafya' => %w[coğrafya kıta ülke şehir dağ nehir ada okyanus iklim bölge],
  'Müzik' => %w[müzik melodi ritim nota enstrüman konser albüm şarkı sanatçı beste],
  'Teknoloji' => %w[teknoloji yazılım donanım sistem ağ veri güvenlik uygulama platform algoritma],
  'Yemek' => %w[yemek tarif mutfak malzeme lezzet sos baharat pişirme tatlı içecek],
  'Doğa' => %w[doğa orman nehir ekosistem habitat canlı bitki hayvan iklim biyoçeşitlilik],
  'Sanat' => %w[sanat eser galeri sergi müze kompozisyon heykel resim estetik akım]
}.freeze

CATEGORY_QUERIES = {
  'Diziler & Filmler' => [
    '?item wdt:P31 wd:Q11424 .',
    '?item wdt:P31 wd:Q5398426 .',
    '?item wdt:P31 wd:Q24856 .'
  ],
  'Astronomi, Fizik & Mühendislik' => [
    '?item wdt:P31 wd:Q6999 .',
    '?item wdt:P31 wd:Q173227 .',
    '?item wdt:P31 wd:Q107715 .',
    '?item wdt:P31 wd:Q811979 .',
    '?item wdt:P31 wd:Q47574 .',
    '?item wdt:P106 wd:Q169470 .',
    '?item wdt:P106 wd:Q11063 .',
    '?item wdt:P106 wd:Q81096 .'
  ],
  'Spor' => [
    '?item wdt:P31 wd:Q349 .',
    '?item wdt:P31 wd:Q12973014 .',
    '?item wdt:P31 wd:Q16510064 .',
    '?item wdt:P31 wd:Q483110 .',
    '?item wdt:P106 wd:Q2066131 .'
  ],
  'Tarih' => [
    '?item wdt:P31 wd:Q13418847 .',
    '?item wdt:P31 wd:Q198 .',
    '?item wdt:P31 wd:Q131569 .',
    '?item wdt:P31 wd:Q188 .',
    '?item wdt:P31 wd:Q11514315 .'
  ],
  'Coğrafya' => [
    '?item wdt:P31 wd:Q6256 .',
    '?item wdt:P31 wd:Q515 .',
    '?item wdt:P31 wd:Q8502 .',
    '?item wdt:P31 wd:Q4022 .',
    '?item wdt:P31 wd:Q23442 .',
    '?item wdt:P31 wd:Q165 .'
  ],
  'Müzik' => [
    '?item wdt:P31 wd:Q7366 .',
    '?item wdt:P31 wd:Q482994 .',
    '?item wdt:P31 wd:Q215380 .',
    '?item wdt:P31 wd:Q34379 .',
    '?item wdt:P106 wd:Q177220 .',
    '?item wdt:P106 wd:Q36834 .'
  ],
  'Teknoloji' => [
    '?item wdt:P31 wd:Q7397 .',
    '?item wdt:P31 wd:Q9143 .',
    '?item wdt:P31 wd:Q9135 .',
    '?item wdt:P31 wd:Q3966 .',
    '{ ?item wdt:P31 wd:Q783794 . ?item wdt:P452 wd:Q11661 . }',
    '?item wdt:P31 wd:Q7889 .'
  ],
  'Yemek' => [
    '?item wdt:P31 wd:Q2095 .',
    '?item wdt:P31 wd:Q746549 .',
    '?item wdt:P31 wd:Q40050 .',
    '?item wdt:P31 wd:Q42527 .',
    '?item wdt:P31 wd:Q3314483 .'
  ],
  'Doğa' => [
    '?item wdt:P31 wd:Q729 .',
    '?item wdt:P31 wd:Q756 .',
    '?item wdt:P31 wd:Q1322005 .',
    '?item wdt:P31 wd:Q193668 .',
    '?item wdt:P31 wd:Q46169 .'
  ],
  'Sanat' => [
    '?item wdt:P31 wd:Q838948 .',
    '?item wdt:P31 wd:Q3305213 .',
    '?item wdt:P31 wd:Q860861 .',
    '?item wdt:P31 wd:Q968159 .',
    '?item wdt:P31 wd:Q33506 .',
    '?item wdt:P106 wd:Q483501 .'
  ]
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

def contains_banned_generic?(text)
  normalized = normalize_text(text)
  GENERIC_BANNED.any? do |needle|
    n = normalize_text(needle)
    normalized == n || normalized.start_with?("#{n} ") || normalized.end_with?(" #{n}") || normalized.include?(" #{n} ")
  end
end

def clean_label(text)
  value = text.to_s.strip
  value = value.gsub(/\s*\([^)]*\)\s*$/, '')
  value = value.gsub(/\s+/, ' ').strip
  value
end

def human_tokens(text)
  text
    .to_s
    .scan(/\p{L}[\p{L}\p{Mn}\p{Pd}]*/u)
    .map(&:strip)
    .reject(&:empty?)
end

def significant_tokens(text)
  human_tokens(text).reject do |token|
    normalized = normalize_text(token)
    normalized.empty? || normalized.length < 2 || STOPWORDS.include?(normalized) || normalized.match?(/^\d+$/)
  end
end

def valid_word?(word)
  return false if word.nil? || word.empty?
  return false if contains_banned_generic?(word)
  return false if word.match?(/^Q\d+$/i)
  return false if word.length < 2 || word.length > MAX_WORD_LENGTH

  normalized = normalize_text(word)
  return false if normalized.empty?
  return false if normalized.include?('wikimedia') || normalized.include?('disambiguation')
  return false if normalized.match?(/\b\d{4}\b/)
  return false if normalized.include?(' men s ') || normalized.include?(' women s ')
  return false if normalized.include?(' world championships ')
  return false if normalized.include?(' world aquatics championships ')
  return false if normalized.include?(' olympic games ')
  return false if normalized.include?(' olympiyatlar ')
  return false if normalized.include?(' at the ') && normalized.length > 30
  return false if normalized.include?(' in the ') && normalized.length > 30

  tokens = significant_tokens(word)
  return false if tokens.length > MAX_TOKEN_COUNT
  
  return false if SENSITIVE_TERMS.any? { |term| normalized.include?(term) }

  true
end

def build_forbidden(word:, description:, category:, seed_index:)
  normalized_word = normalize_text(word)
  pool = []

  label_tokens = significant_tokens(word)
  desc_tokens = significant_tokens(description)

  pool.concat(label_tokens.first(3))
  pool.concat(desc_tokens.first(8))

  terms = CATEGORY_TERMS.fetch(category)
  pool << terms[seed_index % terms.length]
  pool << terms[(seed_index + 3) % terms.length]
  pool << terms[(seed_index + 6) % terms.length]

  forbidden = []
  used = Set.new

  pool.each do |candidate|
    c = candidate.to_s.strip
    n = normalize_text(c)
    next if c.empty? || n.empty? || n == normalized_word || used.include?(n)
    next if contains_banned_generic?(c)

    used << n
    forbidden << c
    break if forbidden.length == 5
  end

  terms.each do |fallback|
    break if forbidden.length == 5
    c = fallback.to_s.strip
    n = normalize_text(c)
    next if c.empty? || n.empty? || n == normalized_word || used.include?(n)
    next if contains_banned_generic?(c)

    used << n
    forbidden << c
  end

  while forbidden.length < 5
    filler = terms[(seed_index + forbidden.length) % terms.length]
    n = normalize_text(filler)
    next if used.include?(n) || n == normalized_word
    used << n
    forbidden << filler
  end

  forbidden
end

def build_query(clauses:, limit:, offset:)
  unions = clauses.map do |clause|
    clause.strip.start_with?('{') ? clause.strip : "{ #{clause} }"
  end

  <<~SPARQL
    SELECT DISTINCT ?item ?itemLabel ?itemDescription WHERE {
      #{unions.join("\n      UNION\n      ")}
      SERVICE wikibase:label { bd:serviceParam wikibase:language "tr,en". }
    }
    LIMIT #{limit}
    OFFSET #{offset}
  SPARQL
end

def sparql_request(query)
  stdout, stderr, status = Open3.capture3(
    'curl',
    '-sS',
    '-G',
    'https://query.wikidata.org/sparql',
    '--data-urlencode',
    'format=json',
    '--data-urlencode',
    "query=#{query}",
    '-H',
    'User-Agent: TabuCatalogBuilder/1.0'
  )

  unless status.success?
    raise "Wikidata isteği başarısız: #{stderr.strip}"
  end

  JSON.parse(stdout)
end

def fetch_rows_for_category(category, clauses, needed)
  rows = []
  seen_ids = Set.new
  batch = 700
  offset = 0
  max_offset = 28_000

  while rows.length < (needed * 8) && offset <= max_offset
    query = build_query(clauses: clauses, limit: batch, offset: offset)

    response = nil
    attempts = 0
    begin
      response = sparql_request(query)
    rescue StandardError => e
      attempts += 1
      raise e if attempts >= 4
      sleep(1.0 * attempts)
      retry
    end

    bindings = response.dig('results', 'bindings') || []
    break if bindings.empty?

    bindings.each do |item|
      item_id = item.dig('item', 'value').to_s
      next if item_id.empty? || seen_ids.include?(item_id)
      seen_ids << item_id

      rows << {
        'id' => item_id,
        'label' => item.dig('itemLabel', 'value').to_s,
        'description' => item.dig('itemDescription', 'value').to_s
      }
    end

    offset += batch
    sleep(0.25)
  end

  rows
end

def difficulty_targets(total)
  easy = (total * 0.35).round
  medium = (total * 0.45).round
  hard = total - easy - medium
  { 'easy' => easy, 'medium' => medium, 'hard' => hard }
end

def difficulty_score(word)
  normalized = normalize_text(word)
  tokens = significant_tokens(word)
  score = normalized.length
  score += tokens.length * 6
  score += 8 if normalized.include?(' ')
  score += 10 if word.include?(':') || word.include?('-')
  score
end

def assign_difficulties!(entries)
  targets = difficulty_targets(entries.length)
  ranked = entries.each_with_index.map { |entry, index| [index, difficulty_score(entry['Kelime'])] }
  ranked.sort_by! { |(_, score)| score }

  easy_cut = targets['easy']
  medium_cut = targets['easy'] + targets['medium']

  ranked.each_with_index do |(entry_index, _score), position|
    difficulty = if position < easy_cut
                   'easy'
                 elsif position < medium_cut
                   'medium'
                 else
                   'hard'
                 end
    entries[entry_index]['Zorluk'] = difficulty
  end
end

def category_entries(category, raw_rows, global_seen, target_count)
  entries = []
  local_seen = Set.new

  raw_rows.each_with_index do |row, idx|
    break if entries.length >= target_count

    word = clean_label(row['label'])
    next unless valid_word?(word)

    norm = normalize_text(word)
    next if norm.empty? || local_seen.include?(norm) || global_seen.include?(norm)

    forbidden = build_forbidden(
      word: word,
      description: row['description'],
      category: category,
      seed_index: entries.length + idx
    )

    entries << {
      'Kelime' => word,
      'Yasaklılar' => forbidden,
      '_Kaynak' => row['id']
    }

    local_seen << norm
    global_seen << norm
  end

  entries
end

output_path = ARGV[0] || File.expand_path('../Tabu/Files/Kelimeler.json', __dir__)
source_manifest_path = ARGV[1] || File.expand_path('../Tabu/Files/Kelimeler.sources.json', __dir__)

catalog = {}
manifest = {
  'generatedAt' => Time.now.utc.iso8601,
  'source' => 'Wikidata',
  'categories' => {},
  'items' => {}
}

global_seen = Set.new

TARGET_CATEGORIES.each do |category|
  clauses = CATEGORY_QUERIES.fetch(category)
  rows = fetch_rows_for_category(category, clauses, TARGET_COUNT)

  entries = category_entries(category, rows, global_seen, TARGET_COUNT)

  if entries.length < TARGET_COUNT
    warn "Kategori için yeterli doğrulanabilir kayıt çekilemedi: #{category} (#{entries.length}/#{TARGET_COUNT})"
    exit(1)
  end

  assign_difficulties!(entries)
  
  manifest['items'][category] = entries.map do |entry|
    {
      'Kelime' => entry['Kelime'],
      'Wikidata' => entry['_Kaynak']
    }
  end
  
  entries.each { |entry| entry.delete('_Kaynak') }
  catalog[category] = entries

  manifest['categories'][category] = {
    'queryClauses' => clauses,
    'fetchedRows' => rows.length,
    'selectedRows' => entries.length
  }
end

File.write(output_path, JSON.pretty_generate(catalog))
File.write(source_manifest_path, JSON.pretty_generate(manifest))

puts "Katalog üretildi: #{output_path}"
puts "Kaynak özeti: #{source_manifest_path}"
puts "Kategori sayısı: #{catalog.keys.length}"
puts "Toplam kart: #{catalog.values.sum(&:length)}"
catalog.each do |category, entries|
  counts = entries.each_with_object(Hash.new(0)) { |entry, memo| memo[entry['Zorluk']] += 1 }
  puts "- #{category}: #{entries.length} (easy=#{counts['easy']}, medium=#{counts['medium']}, hard=#{counts['hard']})"
end

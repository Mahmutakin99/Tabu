#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

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

def extract_source_id(raw_value)
  value = raw_value.to_s.strip
  return nil if value.empty?

  if (match = value.match(/[QL]\d+(?:-S\d+)?/i))
    match[0].upcase
  else
    nil
  end
end

def fail_with(errors)
  warn 'Kaynak hizalama doğrulaması başarısız.'
  errors.first(120).each { |error| warn "- #{error}" }
  warn "Toplam hata: #{errors.length}" if errors.length > 120
  exit(1)
end

catalog_path = ARGV[0] || File.expand_path('../Tabu/Files/Kelimeler.json', __dir__)
sources_path = ARGV[1] || File.expand_path('../catalog/Kelimeler.sources.json', __dir__)

catalog = JSON.parse(File.read(catalog_path))
sources = JSON.parse(File.read(sources_path))

errors = []

unless catalog.is_a?(Hash)
  fail_with(['Kelimeler.json kökü bir nesne (hash) olmalı.'])
end

unless sources.is_a?(Hash)
  fail_with(['Kelimeler.sources.json kökü bir nesne (hash) olmalı.'])
end

source_items = sources['items']
unless source_items.is_a?(Hash)
  fail_with(["Kelimeler.sources.json içinde 'items' nesnesi bulunamadı."])
end

missing_catalog_categories = TARGET_CATEGORIES - catalog.keys
extra_catalog_categories = catalog.keys - TARGET_CATEGORIES
missing_source_categories = TARGET_CATEGORIES - source_items.keys
extra_source_categories = source_items.keys - TARGET_CATEGORIES

errors << "Kelimeler.json eksik kategoriler: #{missing_catalog_categories.join(', ')}" if missing_catalog_categories.any?
errors << "Kelimeler.json fazla kategoriler: #{extra_catalog_categories.join(', ')}" if extra_catalog_categories.any?
errors << "Kelimeler.sources.json eksik kategoriler: #{missing_source_categories.join(', ')}" if missing_source_categories.any?
errors << "Kelimeler.sources.json fazla kategoriler: #{extra_source_categories.join(', ')}" if extra_source_categories.any?

summary = {}

TARGET_CATEGORIES.each do |category|
  catalog_entries = catalog[category]
  source_entries = source_items[category]

  unless catalog_entries.is_a?(Array)
    errors << "#{category}: Kelimeler.json kategori değeri dizi olmalı."
    next
  end

  unless source_entries.is_a?(Array)
    errors << "#{category}: Kelimeler.sources.json kategori değeri dizi olmalı."
    next
  end

  source_by_id = {}
  source_by_word = {}

  source_entries.each_with_index do |item, idx|
    unless item.is_a?(Hash)
      errors << "#{category}/sources[#{idx}]: kayıt nesne olmalı."
      next
    end

    word = item['Kelime']
    source_id = extract_source_id(item['Wikidata'])

    if !word.is_a?(String) || word.strip.empty?
      errors << "#{category}/sources[#{idx}]: Kelime alanı boş/geçersiz."
      next
    end

    if source_id.nil?
      errors << "#{category}/sources[#{idx}] '#{word}': Wikidata alanı geçersiz."
      next
    end

    normalized_word = normalize_text(word)
    if normalized_word.empty?
      errors << "#{category}/sources[#{idx}] '#{word}': normalize sonrası boş."
      next
    end

    if source_by_id.key?(source_id)
      errors << "#{category}/sources[#{idx}] '#{word}': duplicate Wikidata '#{source_id}'."
    else
      source_by_id[source_id] = normalized_word
    end

    if source_by_word.key?(normalized_word)
      errors << "#{category}/sources[#{idx}] '#{word}': duplicate kelime."
    else
      source_by_word[normalized_word] = source_id
    end
  end

  matched_by_source_id = 0
  matched_by_word = 0

  catalog_entries.each_with_index do |item, idx|
    unless item.is_a?(Hash)
      errors << "#{category}/catalog[#{idx}]: kayıt nesne olmalı."
      next
    end

    word = item['Kelime']
    source_id = item['KaynakID']

    if !word.is_a?(String) || word.strip.empty?
      errors << "#{category}/catalog[#{idx}]: Kelime alanı boş/geçersiz."
      next
    end

    normalized_word = normalize_text(word)
    if normalized_word.empty?
      errors << "#{category}/catalog[#{idx}] '#{word}': normalize sonrası boş."
      next
    end

    if source_id.is_a?(String) && source_id.match?(/\A[QL]\d+(?:-S\d+)?\z/) && source_by_id.key?(source_id)
      matched_by_source_id += 1
      next
    end

    if source_by_word.key?(normalized_word)
      matched_by_word += 1
    else
      errors << "#{category}/catalog '#{word}': sources eşleşmesi bulunamadı (KaynakID='#{source_id}')."
    end
  end

  matched = matched_by_source_id + matched_by_word
  ratio = catalog_entries.empty? ? 0.0 : (matched.to_f / catalog_entries.length.to_f * 100.0)

  summary[category] = {
    'catalogWords' => catalog_entries.length,
    'sourceWords' => source_entries.length,
    'matchedBySourceID' => matched_by_source_id,
    'matchedByWord' => matched_by_word,
    'ratio' => ratio.round(2)
  }

  if matched != catalog_entries.length
    errors << "#{category}: eşleşme oranı %#{ratio.round(2)} (%100 bekleniyor)."
  end
end

fail_with(errors) if errors.any?

puts 'Kaynak hizalama doğrulaması başarılı.'
puts "Kelimeler: #{catalog_path}"
puts "Kaynak: #{sources_path}"
TARGET_CATEGORIES.each do |category|
  item = summary[category]
  next if item.nil?

  puts "- #{category}: catalog=#{item['catalogWords']}, sources=#{item['sourceWords']}, byId=#{item['matchedBySourceID']}, byWord=#{item['matchedByWord']}, ratio=%#{item['ratio']}"
end

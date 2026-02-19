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

def fail_with(errors)
  warn 'Kaynak hizalama doğrulaması başarısız.'
  errors.first(120).each { |error| warn "- #{error}" }
  warn "Toplam hata: #{errors.length}" if errors.length > 120
  exit(1)
end

catalog_path = ARGV[0] || File.expand_path('../Tabu/Files/Kelimeler.json', __dir__)
sources_path = ARGV[1] || File.expand_path('../Tabu/Files/Kelimeler.sources.json', __dir__)

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
  
  source_word_to_id = {}
  
  source_entries.each_with_index do |item, idx|
    unless item.is_a?(Hash)
      errors << "#{category}/sources[#{idx}]: kayıt nesne olmalı."
      next
    end
    
    source_word = item['Kelime']
    source_id = item['Wikidata']
    
    if !source_word.is_a?(String) || source_word.strip.empty?
      errors << "#{category}/sources[#{idx}]: Kelime alanı boş/geçersiz."
      next
    end
    
    if !source_id.is_a?(String) || source_id.strip.empty?
      errors << "#{category}/sources[#{idx}] '#{source_word}': Wikidata alanı boş/geçersiz."
      next
    end
    
    normalized = normalize_text(source_word)
    if normalized.empty?
      errors << "#{category}/sources[#{idx}] '#{source_word}': normalize sonrası boş."
      next
    end
    
    if source_word_to_id.key?(normalized)
      errors << "#{category}/sources[#{idx}] '#{source_word}': sources içinde duplicate kelime."
      next
    end
    
    source_word_to_id[normalized] = source_id
  end
  
  matched = 0
  catalog_words = Set.new
  
  catalog_entries.each_with_index do |item, idx|
    unless item.is_a?(Hash)
      errors << "#{category}/catalog[#{idx}]: kayıt nesne olmalı."
      next
    end
    
    word = item['Kelime']
    if !word.is_a?(String) || word.strip.empty?
      errors << "#{category}/catalog[#{idx}]: Kelime alanı boş/geçersiz."
      next
    end
    
    normalized = normalize_text(word)
    if normalized.empty?
      errors << "#{category}/catalog[#{idx}] '#{word}': normalize sonrası boş."
      next
    end
    
    if catalog_words.include?(normalized)
      errors << "#{category}/catalog[#{idx}] '#{word}': katalog içinde duplicate kelime."
      next
    end
    catalog_words << normalized
    
    if source_word_to_id.key?(normalized)
      matched += 1
    else
      errors << "#{category}/catalog '#{word}': sources eşleşmesi bulunamadı."
    end
  end
  
  ratio = catalog_words.empty? ? 0.0 : (matched.to_f / catalog_words.length.to_f * 100.0)
  summary[category] = {
    'catalogWords' => catalog_words.length,
    'sourceWords' => source_word_to_id.length,
    'matched' => matched,
    'ratio' => ratio.round(2)
  }
  
  if matched != catalog_words.length
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
  puts "- #{category}: catalog=#{item['catalogWords']}, sources=#{item['sourceWords']}, matched=#{item['matched']}, ratio=%#{item['ratio']}"
end

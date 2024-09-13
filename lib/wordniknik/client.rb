# frozen_string_literal: true

require 'json'
require 'net/http'

module Wordniknik
  class Error < StandardError; end

  class Client
    attr_accessor :configuration

    # Initializes a new Wordniknik::Client object.
    # @param configuration [Wordniknik::Configuration] the configuration to use.
    # @param clean_up [Boolean] whether to clean up the results. Default is true.
    #      If true, the results will be cleaned up in various ways. Generally, this means
    #      404 (Missing) results will be returned as empty arrays. Other results will generally
    #      be cleaned up to return arrays. Etyomologies will be cleaned up to remove XML tags.
    def initialize(configuration: nil, http_client: nil, clean_up: true)
      @configuration = configuration || Configuration.new
      @http_client = http_client || create_net_https_client
      @clean_up = clean_up
    end

    # Fetches audio metadata for a word.
    # @param word [String] the word to fetch audio metadata for.
    # @param limit [Integer] the maximum number of results to return. Default is 50.
    # @return [Array] Array of hashes containing audio metadata.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def audio(word, limit = 50)
      params = { limit: limit }
      results = call_with_path("word.json/#{word}/audio", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up && results.is_a?(Hash) ? [] : results
    end

    # Fetches definitions for a word.
    # @param word [String] the word to fetch definitions for.
    # @param limit [Integer] the maximum number of results to return. Default is 200.
    # @param part_of_speech [String, Array<String>] the parts of speech to filter by. This can be
    #                       a single string or an array of strings. Default is nil.
    #                       If a single string is provided, it should be comma-separated values
    #                       (e.g. "noun,verb") or just "noun"
    # @param source_dictionaries [String, Array<String>] the source dictionaries to filter by.
    #                       This can be a single string or an array of strings. Default is nil.
    #                       If a single string is provided, it should be comma-separated values
    #                       (e.g. "wiktionary,wordnet") or just "wordnet"
    # @return [Array] Array of hashes containing definitions.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def definitions(word, limit: 200, part_of_speech: nil, source_dictionaries: nil)
      params = { limit: limit }
      params[:part_of_speech] = ensure_csv(part_of_speech) if part_of_speech
      params[:source_dictionaries] = ensure_csv(source_dictionaries) if source_dictionaries
      results = call_with_path("word.json/#{word}/definitions", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up ? results.select { |r| r[:text] } : results
    end

    alias defs definitions

    # Fetches etymologies for a word.
    # @param word [String] the word to fetch etymologies for.
    # @return [Array] Array of strings containing etymologies.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def etymologies(word)
      params = {}
      results = call_with_path("word.json/#{word}/etymologies", params)
      # foolishly, the API returns a 500 error if the word is not found
      raise Wordniknik::Error, results[:message] if results.is_a?(Hash) && results[:status_code] != 500

      if @clean_up && results.is_a?(Hash)
        []
      elsif results.is_a?(Array)
        results.map { |r| cleanup_etymology_result(r) }
      else
        results
      end
    end

    # Fetches examples for a word.
    # @param word [String] the word to fetch examples for.
    # @param include_duplicates [Boolean] whether to include duplicate examples
    # @param skip [Integer] the number of examples to skip. Default is 0.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array, Hash] Array of hashes containing examples, or a hash with an examples: key.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def examples(word, include_duplicates: false, skip: 0, limit: 10)
      params = { limit: limit }
      params[:include_duplicates] = include_duplicates if include_duplicates
      params[:skip] = skip if skip&.positive?
      results = call_with_path("word.json/#{word}/examples", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      if @clean_up && is_404?(results)
        []
      elsif @clean_up && results.is_a?(Hash)
        results[:examples]
      else
        results
      end
    end

    # Fetches frequency data for a word.
    # @param word [String] the word to fetch frequency data for.
    # @param start_year [Integer] the start year for the frequency data. Defaults to 1800.
    # @param end_year [Integer] the end year for the frequency data. Defaults to 2012.
    # @return [Array, Hash] Array of hashes containing frequency data, or a hash with a frequency: key.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def frequency(word, start_year: nil, end_year: nil)
      params = {}
      params[:start_year] = start_year if start_year
      params[:end_year] = end_year if end_year
      results = call_with_path("word.json/#{word}/frequency", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      if @clean_up && is_404?(results)
        []
      elsif @clean_up && is_404?(results)
        results[:frequency]
      else
        results
      end
    end

    # Fetches hyphenation data for a word.
    # @param word [String] the word to fetch hyphenation data for.
    # @param source_dictionary [String] the source dictionary to use. Default is nil.
    # @param limit [Integer] the maximum number of results to return. Default is 50.
    # @return [Array] Array of hashes containing hyphenation data.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def hyphenation(word, source_dictionary: nil, limit: 50)
      params = { limit: limit }
      params[:source_dictionary] = source_dictionary if source_dictionary
      results = call_with_path("word.json/#{word}/hyphenation", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up && is_404?(results) ? [] : results
    end

    # Fetches phrases for a word.
    # @param word [String] the word to fetch phrases for.
    # @param limit [Integer] the maximum number of results to return. Default is 5.
    # @param wlmi [Integer] the minimum weighted mutual information for the phrases returned. What is wlmi?
    #                       I don't know.
    # @return [Array] Array of hashes containing phrases.
    # @raise [Wordniknik::Error] if some error is returned
    def phrases(word, limit: 5, wlmi: nil)
      params = { limit: limit }
      params[:wlmi] = wlmi if wlmi
      results = call_with_path("word.json/#{word}/phrases", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up && is_404?(results) ? [] : results
    end

    # Fetches pronunciations for a word.
    # @param word [String] the word to fetch pronunciations for.
    # @param source_dictionary [String] the source dictionary to use. Default is nil (meaning all)
    # @param type_format [String] the type format to use. Default is nil (meaning all)
    # @param limit [Integer] the maximum number of results to return. Default is 50.
    # @return [Array] Array of hashes containing pronunciations.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def pronunciations(word, source_dictionary: nil, type_format: nil, limit: 50)
      params = { limit: limit }
      params[:source_dictionary] = source_dictionary if source_dictionary
      params[:type_format] = type_format if type_format
      results = call_with_path("word.json/#{word}/pronunciations", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      if @clean_up
        if is_404?(results)
          []
        else
          type_format ? results.select { |r| r[:raw_type] == type_format } : results
        end
      else
        results
      end
    end

    # Fetches related words for a word.
    # @param word [String] the word to fetch related words for.
    # @param relationship_types [String, Array<String>] the relationship types to fetch.
    #                     This can be a single string or an array of strings. Default is nil.
    #                       If a single string is provided, it should be comma-separated values
    #                       (e.g. "form,equivalent") or just "form"
    # @param limit_per_relationship_type [Integer] the maximum number of results to return per relationship type.
    def related_words(word, relationship_types: nil, limit_per_relationship_type: 10)
      params = { limit_per_relationship_type: limit_per_relationship_type }
      params[:relationship_types] = ensure_csv(relationship_types) if relationship_types
      results = call_with_path("word.json/#{word}/relatedWords", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up && is_404?(results) ? [] : results
    end

    # Fetches the Scrabble score for a word.
    # @param word [String] the word to fetch the Scrabble score for.
    # @return [Integer] the Scrabble score for the word.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def scrabble_score(word, params = {})
      results = call_with_path("word.json/#{word}/scrabbleScore", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      if @clean_up && is_404?(results)
        0
      elsif @clean_up && results.is_a?(Hash)
        results[:value]
      else
        results
      end
    end

    # Fetches the top example for a word.
    # @param word [String] the word to fetch the top example for.
    # @return [Hash] the top example for the word.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def top_example(word)
      params = {}
      results = call_with_path("word.json/#{word}/topExample", params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      if @clean_up && is_404?(results)
        {}
      elsif @clean_up && results.is_a?(Hash)
        results
      else
        results
      end
    end

    # Fetches a random word.
    # @param has_dictionary_def [Boolean] only return words with dictionary definitions, defaults to true.
    # @param include_part_of_speech [String, Array<String>] the parts of speech to include. Default is nil, meaning all.
    #              This can be a single string or an array of strings.
    #              If a single string is provided, it should be comma-separated values,
    #              (e.g. "noun,verb") or just "noun"
    # @param exclude_part_of_speech [String, Array<String>] the parts of speech to exclude. Default is ni, meaning none.
    #              This can be a single string or an array of strings.
    #              If a single string is provided, it should be comma-separated values,
    #              (e.g. "noun,verb") or just "noun"
    # @param min_corpus_count [Integer] the minimum corpus count for the word, defaults to nil, meaning no minimum.
    # @param max_corpus_count [Integer] the maximum corpus count for the word, defaults to nil, meaning no maximum.
    # @param min_dictionary_count [Integer] the minimum dictionary count for the word, defaults to nil, meaning none.
    # @param max_dictionary_count [Integer] the maximum dictionary count for the word, defaults to nil, meaning none.
    # @param min_length [Integer] the minimum length of the word, defaults to nil, meaning no minimum.
    # @param max_length [Integer] the maximum length of the word, defaults to nil, meaning no maximum.
    # @return [String, Hash] the random word.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def random_word(has_dictionary_def: true, include_part_of_speech: nil, exclude_part_of_speech: nil,
                    min_corpus_count: nil, max_corpus_count: nil, min_dictionary_count: nil, max_dictionary_count: nil,
                    min_length: nil, max_length: nil)
      params = {}
      params[:has_dictionary_def] = has_dictionary_def if has_dictionary_def
      params[:include_part_of_speech] = ensure_csv(include_part_of_speech) if include_part_of_speech
      params[:exclude_part_of_speech] = ensure_csv(exclude_part_of_speech) if exclude_part_of_speech
      params[:min_corpus_count] = min_corpus_count if min_corpus_count
      params[:max_corpus_count] = max_corpus_count if max_corpus_count
      params[:min_dictionary_count] = min_dictionary_count if min_dictionary_count
      params[:max_dictionary_count] = max_dictionary_count if max_dictionary_count
      params[:min_length] = min_length if min_length
      params[:max_length] = max_length if max_length
      results = call_with_path('words.json/randomWord', params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up ? results[:word] : results
    end

    def random_words(has_dictionary_def: true, include_part_of_speech: nil, exclude_part_of_speech: nil,
                     min_corpus_count: nil, max_corpus_count: nil, min_dictionary_count: nil, max_dictionary_count: nil,
                     min_length: nil, max_length: nil, limit: 10)
      params = { limit: limit }
      params[:has_dictionary_def] = has_dictionary_def if has_dictionary_def
      params[:include_part_of_speech] = ensure_csv(include_part_of_speech) if include_part_of_speech
      params[:exclude_part_of_speech] = ensure_csv(exclude_part_of_speech) if exclude_part_of_speech
      params[:min_corpus_count] = min_corpus_count if min_corpus_count
      params[:max_corpus_count] = max_corpus_count if max_corpus_count
      params[:min_dictionary_count] = min_dictionary_count if min_dictionary_count
      params[:max_dictionary_count] = max_dictionary_count if max_dictionary_count
      params[:min_length] = min_length if min_length
      params[:max_length] = max_length if max_length
      results = call_with_path('words.json/randomWords', params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up ? results.map { |w| w[:word] } : results
    end

    # reverse_dictionary is deprecated
    # def reverse_dictionary(word, params = {})
    #   call_with_path("words.json/reverseDictionary", params)
    # end

    # search is deprecated
    # def search(query, params = {})
    #   call_with_path("words.json/search/#{query}", params)
    # end

    def word_of_the_day(date: nil)
      params = {}
      params[:date] = date if date
      results = call_with_path('words.json/wordOfTheDay', params)
      raise Wordniknik::Error, results[:message] if is_error?(results)

      @clean_up && results == '' ? nil : results
    end

    alias wotd word_of_the_day

    ## Extras!

    # Fetches rhymes for a word.
    # @param word [String] the word to fetch rhymes for.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array] Array of antonyms.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def rhymes(_word, limit: 10)
      related_words('suffering', relationship_types: :rhyme, limit_per_relationship_type: limit).map do |r|
        r[:words]
      end.flatten
    end

    # Fetches antonyms for a word.
    # @param word [String] the word to fetch antonyms for.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array] Array of antonyms.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def antonyms(word, limit: 10)
      related_words(word, relationship_types: :antonym, limit_per_relationship_type: limit).map do |r|
        r[:words]
      end.flatten
    end

    # Fetches synonyms for a word.
    # @param word [String] the word to fetch synonyms for.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array] Array of antonyms.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def synonyms(word, limit: 10)
      related_words(word, relationship_types: :synonym, limit_per_relationship_type: limit).map do |r|
        r[:words]
      end.flatten
    end

    # Fetches hypernyms for a word.
    # @param word [String] the word to fetch hypernyms for.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array] Array of antonyms.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def hypernyms(word, limit: 10)
      related_words(word, relationship_types: :hypernym, limit_per_relationship_type: limit).map do |r|
        r[:words]
      end.flatten
    end

    # Fetches hyponyms for a word.
    # @param word [String] the word to fetch hyponyms for.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array] Array of antonyms.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def hyponyms(word, limit: 10)
      related_words(word, relationship_types: :hyponym, limit_per_relationship_type: limit).map do |r|
        r[:words]
      end.flatten
    end

    # Fetches equivalents for a word.
    # @param word [String] the word to fetch equivalents for.
    # @param limit [Integer] the maximum number of results to return. Default is 10.
    # @return [Array] Array of antonyms.
    # @raise [Wordniknik::Error] if some error is returned by the API.
    def equivalents(word, limit: 10)
      related_words(word, relationship_types: :equivalent, limit_per_relationship_type: limit).map do |r|
        r[:words]
      end.flatten
    end

    private

    def create_net_https_client
      client = Net::HTTP.new(@configuration.api_host, @configuration.api_port)
      client.use_ssl = true
      client
    end

    def call(url, params)
      params[:api_key] = @configuration.api_key
      uri = URI.parse(url)
      uri.query = URI.encode_www_form(params)
      response = @http_client.get(uri)
      JSON.parse(response.body, symbolize_names: true)
    end

    def compose_url(path)
      "https://#{configuration.api_host}/#{configuration.api_version}/#{path}"
    end

    def normalize_params(params)
      Wordniknik.to_camel_case(params)
    end

    def call_with_path(path, params)
      url = compose_url(path)
      params = normalize_params(params)
      b = call(url, params)
      Wordniknik.to_snake_case(b)
    end

    def ensure_csv(value)
      value.is_a?(Array) ? value.join(',') : value
    end

    def cleanup_etymology_result(result)
      # looks like this: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<ety>[AS. <ets>hÔøΩsian</ets>.]</ety>\n"
      # want to return this: "AS. hÔøΩsian"
      result.gsub(/<.*?>/, '').gsub(/[\n\r]/, '').gsub(/[\[\]]/, '').strip
    end

    def is_404?(result)
      result.is_a?(Hash) && result[:status_code] == 404
    end

    def is_error?(result)
      result.is_a?(Hash) && result[:status_code] && result[:status_code] != 200 && result[:status_code] != 404
    end
  end
end

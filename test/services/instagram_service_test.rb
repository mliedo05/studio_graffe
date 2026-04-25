require "test_helper"

class InstagramServiceTest < ActiveSupport::TestCase
  SAMPLE_POSTS = [
    { "id" => "1", "media_type" => "IMAGE", "media_url" => "https://cdn.example.com/1.jpg", "permalink" => "https://www.instagram.com/p/abc/", "timestamp" => "2025-01-01T00:00:00Z" },
    { "id" => "2", "media_type" => "IMAGE", "media_url" => "https://cdn.example.com/2.jpg", "permalink" => "https://www.instagram.com/p/def/", "timestamp" => "2025-01-02T00:00:00Z" }
  ].freeze

  # Subclass that overrides the private fetch_from_api for test isolation
  class StubService < InstagramService
    attr_reader :call_count

    def initialize(result: [], error: nil)
      @stub_result = result
      @stub_error  = error
      @call_count  = 0
    end

    def fetch_from_api(limit:)
      @call_count += 1
      raise @stub_error if @stub_error
      @stub_result
    end
  end

  test "retorna resultados desde la API cuando hay posts" do
    svc = StubService.new(result: SAMPLE_POSTS)
    result = svc.fetch_posts
    assert_equal SAMPLE_POSTS, result
  end

  test "llama a fetch_from_api al obtener posts" do
    svc = StubService.new(result: SAMPLE_POSTS)
    svc.fetch_posts
    assert_equal 1, svc.call_count
  end

  test "retorna [] cuando la API devuelve resultado vacío" do
    svc = StubService.new(result: [])
    assert_equal [], svc.fetch_posts
  end

  test "retorna [] cuando fetch_from_api lanza SocketError" do
    svc = StubService.new(error: SocketError.new("Connection refused"))
    assert_equal [], svc.fetch_posts
  end

  test "retorna [] cuando fetch_from_api lanza RuntimeError" do
    svc = StubService.new(error: RuntimeError.new("API error"))
    assert_equal [], svc.fetch_posts
  end

  test "retorna [] cuando token está en blanco (simulado con resultado vacío)" do
    svc = StubService.new(result: [])
    assert_equal [], svc.fetch_posts
  end

  test "usa caché cuando está disponible (memory_store)" do
    # Swap to memory_store temporarily to test caching behavior
    original_cache = Rails.cache
    memory_cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache = memory_cache

    begin
      svc = StubService.new(result: SAMPLE_POSTS)
      svc.fetch_posts  # first call — populates cache
      assert_equal 1, svc.call_count

      svc2 = StubService.new(result: SAMPLE_POSTS)
      svc2.fetch_posts  # second call — should hit cache
      assert_equal 0, svc2.call_count, "fetch_from_api no debe llamarse si hay caché"
    ensure
      Rails.cache = original_cache
    end
  end

  test "no almacena en caché cuando la API devuelve vacío (memory_store)" do
    original_cache = Rails.cache
    memory_cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache = memory_cache

    begin
      svc = StubService.new(result: [])
      svc.fetch_posts
      assert_nil memory_cache.read(InstagramService::CACHE_KEY)
    ensure
      Rails.cache = original_cache
    end
  end
end

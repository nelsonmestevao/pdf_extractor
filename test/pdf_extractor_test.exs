defmodule PdfExtractorTest do
  use ExUnit.Case, async: true

  doctest PdfExtractor
  @test_file_path "priv/fixtures/fatura.pdf"
  @test_file_content "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €"

  describe "text/3" do
    test "extracts text from all pages when no page numbers specified" do
      for {page_num, text} <- PdfExtractor.text(@test_file_path) do
        assert is_integer(page_num)
        assert is_binary(text)
      end
    end

    test "extracts text from single page when integer provided" do
      result = PdfExtractor.text(@test_file_path, 0)

      assert is_map(result)
      assert Map.has_key?(result, 0)
      assert is_binary(result[0])
    end

    test "extracts text from multiple specific pages when list provided" do
      result = PdfExtractor.text(@test_file_path, [0])

      assert is_map(result)
      assert Map.has_key?(result, 0)
      assert is_binary(result[0])
    end

    test "extracts text from multiple pages" do
      # First get all pages to know how many we have
      all_pages = PdfExtractor.text(@test_file_path)
      page_count = map_size(all_pages)

      if page_count > 1 do
        result = PdfExtractor.text(@test_file_path, [0, 1])

        assert is_map(result)
        assert Map.has_key?(result, 0)
        assert Map.has_key?(result, 1)
        assert map_size(result) == 2
      else
        # If only one page, test with just that page
        result = PdfExtractor.text(@test_file_path, [0])

        assert is_map(result)
        assert Map.has_key?(result, 0)
        assert map_size(result) == 1
      end
    end

    test "extracts text with area restrictions" do
      # Test with a bounding box area
      areas = %{0 => [0, 0, 300, 200]}
      result = PdfExtractor.text(@test_file_path, [0], areas)

      assert is_map(result)
      assert Map.has_key?(result, 0)
      assert is_binary(result[0])

      # Compare with full page extraction - area should be shorter or equal
      full_result = PdfExtractor.text(@test_file_path, [0])
      area_text_length = String.length(result[0])
      full_text_length = String.length(full_result[0])

      assert area_text_length <= full_text_length
    end

    test "handles different area specifications for different pages" do
      all_pages = PdfExtractor.text(@test_file_path)
      page_count = map_size(all_pages)

      if page_count > 1 do
        areas = %{
          0 => [0, 0, 300, 200],
          1 => [0, 200, 400, 400]
        }

        result = PdfExtractor.text(@test_file_path, [0, 1], areas)

        assert is_map(result)
        assert Map.has_key?(result, 0)
        assert Map.has_key?(result, 1)
        assert is_binary(result[0])
        assert is_binary(result[1])
      else
        # Skip test if only one page
        :ok
      end
    end

    test "handles empty page list" do
      result = PdfExtractor.text(@test_file_path, [])

      assert is_map(result)
      assert map_size(result) > 0
    end

    test "handles non-existent file gracefully" do
      assert_raise(MatchError, fn ->
        PdfExtractor.text("non_existent_file.pdf")
      end)
    end

    test "returns consistent structure for single vs multiple pages" do
      # Single page as integer
      single_result = PdfExtractor.text(@test_file_path, 0)
      assert is_map(single_result)

      # Single page as list
      single_list_result = PdfExtractor.text(@test_file_path, [0])
      assert is_map(single_list_result)

      # Both should have the same content for page 0
      assert single_result[0] == single_list_result[0]
    end

    test "works with various area configurations" do
      # Test with nil area (should work like no area)
      result_with_nil = PdfExtractor.text(@test_file_path, [0], %{0 => nil})
      result_without_area = PdfExtractor.text(@test_file_path, [0])

      assert result_with_nil[0] == result_without_area[0]
    end

    test "extracts non-empty text from test PDF" do
      %{0 => extracted_text} = PdfExtractor.text(@test_file_path, 0)
      assert extracted_text == @test_file_content
    end

    test "pages outside the range are just ignored" do
      assert PdfExtractor.text(@test_file_path, [999]) == %{}
    end
  end
end

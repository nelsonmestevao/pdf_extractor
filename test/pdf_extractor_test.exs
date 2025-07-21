defmodule PdfExtractorTest do
  use ExUnit.Case, async: true

  setup_all do
    start_supervised!(PdfExtractor)

    :ok
  end

  doctest PdfExtractor

  @test_file_path "priv/fixtures/fatura.pdf"
  @test_file_content %{
    0 =>
      "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €",
    1 =>
      "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
  }

  describe "extract_text/3" do
    test "extracts text from all pages when no page numbers specified" do
      assert {:ok, result} = PdfExtractor.extract_text(@test_file_path)

      for {page_num, text} <- result do
        assert is_integer(page_num)
        assert is_binary(text)
        assert text == @test_file_content[page_num]
      end

      assert {:ok, result} = PdfExtractor.extract_text(@test_file_path, [])

      for {page_num, text} <- result do
        assert is_integer(page_num)
        assert is_binary(text)
        assert text == @test_file_content[page_num]
      end
    end

    test "extracts text from single page when integer provided" do
      assert {:ok, result} = PdfExtractor.extract_text(@test_file_path, 0)

      assert is_map(result)
      assert Map.keys(result) == [0]
      assert result[0] == @test_file_content[0]
    end

    test "extracts text from specified pages when list provided" do
      assert {:ok, result} = PdfExtractor.extract_text(@test_file_path, [1])

      assert is_map(result)
      assert Map.keys(result) == [1]
      assert result[1] == @test_file_content[1]

      assert {:ok, result} = PdfExtractor.extract_text(@test_file_path, [0, 1], %{1 => nil})

      assert is_map(result)
      assert Map.keys(result) == [0, 1]
      assert result == @test_file_content
    end

    test "handles different area specifications for different pages" do
      areas = %{
        0 => {0, 0, 300, 200},
        1 => [{0, 0, 300, 400}, {0, 270, 595, 840}]
      }

      assert PdfExtractor.extract_text(@test_file_path, Map.keys(areas), areas) ==
               {:ok,
                %{
                  0 => "Text Example Bill\nProjeto de lei para:\nElixir Company",
                  1 => [
                    "",
                    "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
                  ]
                }}
    end

    test "handles empty page list" do
      assert PdfExtractor.extract_text(@test_file_path, []) == {:ok, @test_file_content}
    end

    test "returns error for non-existent file" do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_text("non_existent_file.pdf")
    end

    test "pages outside the range are just ignored" do
      assert PdfExtractor.extract_text(@test_file_path, [999]) == {:ok, %{}}
    end
  end

  describe "extract_text_from_binary/3" do
    setup do
      [test_file_binary_content: File.read!(@test_file_path)]
    end

    test "extracts text from all pages when no page numbers specified", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert {:ok, result} = PdfExtractor.extract_text_from_binary(test_file_binary_content)

      for {page_num, text} <- result do
        assert is_integer(page_num)
        assert is_binary(text)
        assert text == @test_file_content[page_num]
      end

      assert {:ok, result} = PdfExtractor.extract_text_from_binary(test_file_binary_content, [])

      for {page_num, text} <- result do
        assert is_integer(page_num)
        assert is_binary(text)
        assert text == @test_file_content[page_num]
      end
    end

    test "extracts text from single page when integer provided", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert {:ok, result} = PdfExtractor.extract_text_from_binary(test_file_binary_content, 0)

      assert is_map(result)
      assert Map.keys(result) == [0]
      assert result[0] == @test_file_content[0]
    end

    test "extracts text from specified pages when list provided", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert {:ok, result} = PdfExtractor.extract_text_from_binary(test_file_binary_content, [1])

      assert is_map(result)
      assert Map.keys(result) == [1]
      assert result[1] == @test_file_content[1]

      assert {:ok, result} =
               PdfExtractor.extract_text_from_binary(test_file_binary_content, [0, 1], %{1 => nil})

      assert is_map(result)
      assert Map.keys(result) == [0, 1]
      assert result == @test_file_content
    end

    test "handles different area specifications for different pages", %{
      test_file_binary_content: test_file_binary_content
    } do
      areas = %{
        0 => {0, 0, 300, 200},
        1 => [{0, 0, 300, 400}, {0, 270, 595, 840}]
      }

      assert PdfExtractor.extract_text_from_binary(
               test_file_binary_content,
               Map.keys(areas),
               areas
             ) ==
               {:ok,
                %{
                  0 => "Text Example Bill\nProjeto de lei para:\nElixir Company",
                  1 => [
                    "",
                    "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
                  ]
                }}
    end

    test "handles empty page list", %{test_file_binary_content: test_file_binary_content} do
      assert PdfExtractor.extract_text_from_binary(test_file_binary_content, []) ==
               {:ok, @test_file_content}
    end

    test "pages outside the range are just ignored", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.extract_text_from_binary(test_file_binary_content, [999]) == {:ok, %{}}
    end
  end
end

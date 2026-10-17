defmodule PdfExtractorTest do
  use ExUnit.Case, async: true

  setup do
    pid = start_supervised!({PdfExtractor, []})

    {:ok, %{pid: pid}}
  end

  doctest PdfExtractor

  @test_file_path "priv/fixtures/fatura.pdf"
  @encrypted_file_path "priv/fixtures/fatura-encrypted.pdf"
  @test_file_content %{
    0 =>
      "Text Example Bill FATURA\n# 2025010002\nData: Jun 21, 2025\nProjeto de lei para:\nSaldo devedor: 1 525,59 €\nElixir Company\nItem Quantidade Avaliar Quantia\nTrabalho 1 1 500,00 € 1 500,00 €\nMais trabalho 1 25,59 € 25,59 €\nSubtotal: 1 525,59 €\nImposto (0%): 0,00 €\nTotal: 1 525,59 €",
    1 =>
      "✂\nReceipt Payment part Account / Payable to\nCH4431999123000889012\n✂\nMax Muster & Söhne\nAccount / Payable to\nCH4431999123000889012 Musterstrasse 123\nMax Muster & Söhne 8000 Seldwyla\nMusterstrasse 123\n8000 Seldwyla\nReference\n210000000003139471430009017\nReference\n210000000003139471430009017\nAdditional information\nBestellung vom 15.10.2020\nPayable by (name/address)\nSimon Muster\nPayable by (name/address)\nMusterstrasse 1\nCurrency Amount\nSimon Muster\n8000 Seldwyla\nCHF 1 949.75 Musterstrasse 1\n8000 Seldwyla\nCurrency Amount\nCHF 1 949.75\nAcceptance point"
  }

  @table_rows_with_layout "      Trabalho                                     1          1 500,00 € 1 500,00 €\n      Mais trabalho                                1            25,59 €   25,59 € "

  test "start_link/1 has default values for options and can be restarted", %{pid: pid} do
    assert PdfExtractor.start_link() == {:error, {:already_started, pid}}

    stop_supervised!(PdfExtractor)

    assert {:ok, new_pid} = PdfExtractor.start_link([])
    assert is_pid(new_pid)
    assert new_pid != pid
  end

  test "extracts text using a custom server name" do
    {:ok, pid} = PdfExtractor.start_link(name: :custom_pdf)

    assert {:ok, result} = PdfExtractor.extract_text(@test_file_path, [], name: :custom_pdf)
    assert result == @test_file_content

    GenServer.stop(pid)

    assert catch_exit(PdfExtractor.extract_text(@test_file_path, [], name: :custom_pdf))
  end

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

      assert {:ok, result} = PdfExtractor.extract_text(@test_file_path, [0, 1])

      assert is_map(result)
      assert Map.keys(result) == [0, 1]
      assert result == @test_file_content
    end

    test "handles different area specifications for different pages" do
      areas = %{
        0 => {0, 0, 300, 200},
        1 => [{0, 0, 300, 400}, {0, 270, 595, 840}]
      }

      assert PdfExtractor.extract_text(@test_file_path, areas) ==
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

    test "pages outside the range don't shift the remaining pages" do
      assert PdfExtractor.extract_text(@test_file_path, [999, 1]) ==
               {:ok, %{1 => @test_file_content[1]}}

      assert PdfExtractor.extract_text(@test_file_path, %{-1 => nil, 0 => nil}) ==
               {:ok, %{0 => @test_file_content[0]}}
    end

    test "returns error for invalid pages without crashing the server", %{pid: pid} do
      assert {:error, %FunctionClauseError{}} = PdfExtractor.extract_text(@test_file_path, "0")
      assert Process.alive?(pid)
      assert PdfExtractor.extract_text(@test_file_path) == {:ok, @test_file_content}
    end

    test "keeps the position of the text on the page when layout is true" do
      area = %{0 => {0, 220, 595, 250}}

      assert PdfExtractor.extract_text(@test_file_path, area, layout: true) ==
               {:ok, %{0 => @table_rows_with_layout}}

      assert PdfExtractor.extract_text(@test_file_path, area, layout: false) ==
               PdfExtractor.extract_text(@test_file_path, area)
    end

    test "raises when layout is not a boolean" do
      assert_raise ArgumentError, ~r/expected :layout to be a boolean/, fn ->
        PdfExtractor.extract_text(@test_file_path, [], layout: "yes")
      end
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
               PdfExtractor.extract_text_from_binary(test_file_binary_content, [0, 1])

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

      assert PdfExtractor.extract_text_from_binary(test_file_binary_content, areas) ==
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

    test "pages outside the range don't shift the remaining pages", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.extract_text_from_binary(test_file_binary_content, [999, 1]) ==
               {:ok, %{1 => @test_file_content[1]}}
    end

    test "returns error for invalid binary without crashing the server", %{pid: pid} do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_text_from_binary("not a pdf")
      assert Process.alive?(pid)
    end

    test "keeps the position of the text on the page when layout is true", %{
      test_file_binary_content: test_file_binary_content
    } do
      area = %{0 => {0, 220, 595, 250}}

      assert PdfExtractor.extract_text_from_binary(test_file_binary_content, area, layout: true) ==
               {:ok, %{0 => @table_rows_with_layout}}
    end
  end

  describe "extract_words/3" do
    test "extracts words with their bounding box from all pages when no page numbers specified" do
      assert {:ok, result} = PdfExtractor.extract_words(@test_file_path)

      assert Map.keys(result) == [0, 1]
      assert length(result[0]) == 52
      assert length(result[1]) == 70

      for {_page_number, words} <- result, word <- words do
        assert %{text: text, left: left, right: right, top: top, bottom: bottom} = word
        assert is_binary(text) and text != ""
        assert is_float(left) and is_float(right) and is_float(top) and is_float(bottom)
        assert left < right
        assert top < bottom
      end

      assert PdfExtractor.extract_words(@test_file_path, []) == {:ok, result}
    end

    test "extracts words from single page when integer provided" do
      assert {:ok, result} = PdfExtractor.extract_words(@test_file_path, 0)

      assert Map.keys(result) == [0]

      assert List.first(result[0]) == %{
               text: "Text",
               left: 48.0,
               right: 67.99875,
               top: 26.64224999999999,
               bottom: 36.39224999999999
             }
    end

    test "extracts words from specified pages when list provided" do
      assert {:ok, result} = PdfExtractor.extract_words(@test_file_path, [1])

      assert Map.keys(result) == [1]
      assert Enum.map(Enum.take(result[1], -2), & &1.text) == ["Acceptance", "point"]
    end

    test "words follow the same reading order as the extracted text" do
      assert {:ok, %{0 => words}} = PdfExtractor.extract_words(@test_file_path, 0)

      assert Enum.map_join(words, " ", & &1.text) ==
               String.replace(@test_file_content[0], "\n", " ")
    end

    test "handles different area specifications for different pages" do
      areas = %{
        0 => {0, 0, 300, 200},
        1 => [{0, 0, 300, 400}, {0, 270, 595, 840}]
      }

      assert {:ok, %{0 => page_0, 1 => [[], page_1_bottom]}} =
               PdfExtractor.extract_words(@test_file_path, areas)

      assert Enum.map(page_0, & &1.text) ==
               ~w(Text Example Bill Projeto de lei para: Elixir Company)

      assert Enum.map(Enum.take(page_1_bottom, -2), & &1.text) == ["Acceptance", "point"]
    end

    test "pages outside the range are just ignored" do
      assert PdfExtractor.extract_words(@test_file_path, [999]) == {:ok, %{}}
    end

    test "returns error for non-existent file" do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_words("non_existent_file.pdf")
    end

    test "adds the font of each word when font is true" do
      area = %{0 => {0, 0, 300, 200}}

      assert {:ok, %{0 => words}} = PdfExtractor.extract_words(@test_file_path, area, font: true)

      assert Enum.map(words, &{&1.text, &1.font_name, &1.font_size}) == [
               {"Text", "NimbusSans-Bold", 9.75},
               {"Example", "NimbusSans-Bold", 9.75},
               {"Bill", "NimbusSans-Bold", 9.75},
               {"Projeto", "NimbusSans-Regular", 9.75},
               {"de", "NimbusSans-Regular", 9.75},
               {"lei", "NimbusSans-Regular", 9.75},
               {"para:", "NimbusSans-Regular", 9.75},
               {"Elixir", "NimbusSans-Bold", 9.75},
               {"Company", "NimbusSans-Bold", 9.75}
             ]

      assert {:ok, %{0 => plain_words}} = PdfExtractor.extract_words(@test_file_path, area)
      refute Enum.any?(plain_words, &Map.has_key?(&1, :font_name))
      assert Enum.map(words, &Map.drop(&1, [:font_name, :font_size])) == plain_words
    end

    test "raises when font is not a boolean" do
      assert_raise ArgumentError, ~r/expected :font to be a boolean/, fn ->
        PdfExtractor.extract_words(@test_file_path, [], font: "yes")
      end
    end

    test "returns error for invalid pages without crashing the server", %{pid: pid} do
      assert {:error, %FunctionClauseError{}} = PdfExtractor.extract_words(@test_file_path, "0")
      assert Process.alive?(pid)
      assert {:ok, %{0 => _, 1 => _}} = PdfExtractor.extract_words(@test_file_path)
    end
  end

  describe "extract_words_from_binary/3" do
    setup do
      [test_file_binary_content: File.read!(@test_file_path)]
    end

    test "extracts the same words as the file based function", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.extract_words_from_binary(test_file_binary_content) ==
               PdfExtractor.extract_words(@test_file_path)

      assert PdfExtractor.extract_words_from_binary(test_file_binary_content, 1) ==
               PdfExtractor.extract_words(@test_file_path, 1)
    end

    test "handles different area specifications for different pages", %{
      test_file_binary_content: test_file_binary_content
    } do
      areas = %{
        0 => {0, 0, 300, 200},
        1 => [{0, 0, 300, 400}, {0, 270, 595, 840}]
      }

      assert {:ok, %{0 => page_0, 1 => [[], page_1_bottom]}} =
               PdfExtractor.extract_words_from_binary(test_file_binary_content, areas)

      assert Enum.map(page_0, & &1.text) ==
               ~w(Text Example Bill Projeto de lei para: Elixir Company)

      assert Enum.map(Enum.take(page_1_bottom, -2), & &1.text) == ["Acceptance", "point"]
    end

    test "pages outside the range are just ignored", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.extract_words_from_binary(test_file_binary_content, [999]) ==
               {:ok, %{}}
    end

    test "adds the font of each word when font is true", %{
      test_file_binary_content: test_file_binary_content
    } do
      area = %{0 => {0, 0, 300, 200}}

      assert PdfExtractor.extract_words_from_binary(test_file_binary_content, area, font: true) ==
               PdfExtractor.extract_words(@test_file_path, area, font: true)
    end

    test "returns error for invalid binary without crashing the server", %{pid: pid} do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_words_from_binary("not a pdf")
      assert Process.alive?(pid)
    end
  end

  describe "extract_tables/3" do
    @header_table %{
      rows: [["Item", "Quantidade", "Avaliar", "Quantia"]],
      left: 29.25,
      top: 190.5,
      right: 582.75,
      bottom: 211.5
    }

    test "extracts the tables of all pages when no page numbers specified" do
      assert PdfExtractor.extract_tables(@test_file_path) ==
               {:ok, %{0 => [@header_table], 1 => []}}

      assert PdfExtractor.extract_tables(@test_file_path, []) ==
               {:ok, %{0 => [@header_table], 1 => []}}
    end

    test "extracts tables from single page when integer provided" do
      assert PdfExtractor.extract_tables(@test_file_path, 0) == {:ok, %{0 => [@header_table]}}
      assert PdfExtractor.extract_tables(@test_file_path, 1) == {:ok, %{1 => []}}
    end

    test "handles different area specifications for different pages" do
      areas = %{0 => {0, 180, 595, 260}, 1 => [{0, 0, 300, 400}]}

      assert PdfExtractor.extract_tables(@test_file_path, areas) ==
               {:ok, %{0 => [@header_table], 1 => [[]]}}
    end

    test "finds tables without drawn lines from the alignment of the words" do
      assert {:ok, %{0 => [table]}} =
               PdfExtractor.extract_tables(@test_file_path, 0,
                 vertical_strategy: :text,
                 horizontal_strategy: :text
               )

      assert length(table.rows) == 23
      assert Enum.all?(table.rows, &(length(&1) == 6))
      assert List.last(table.rows) == ["", "", "Total:", "", "1 5", "25,59 €"]

      assert {table.left, table.top, table.right, table.bottom} ==
               {44.25, 27.20625000000001, 568.0695, 356.64225}
    end

    test "returns nil for cells without text" do
      assert {:ok, %{0 => [%{rows: [first_row | _]}]}} =
               PdfExtractor.extract_tables(@test_file_path, 0,
                 vertical_strategy: :text,
                 horizontal_strategy: :lines
               )

      assert first_row == [nil, nil, "devedor:", "", "1 52", "5,59 €"]
    end

    test "raises for an unknown strategy" do
      assert_raise ArgumentError, ~r/expected :vertical_strategy to be one of/, fn ->
        PdfExtractor.extract_tables(@test_file_path, [], vertical_strategy: :magic)
      end

      assert_raise ArgumentError, ~r/expected :horizontal_strategy to be one of/, fn ->
        PdfExtractor.extract_tables(@test_file_path, [], horizontal_strategy: "lines")
      end
    end

    test "pages outside the range are just ignored" do
      assert PdfExtractor.extract_tables(@test_file_path, [999]) == {:ok, %{}}
    end

    test "returns error for non-existent file" do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_tables("non_existent_file.pdf")
    end

    test "returns error for invalid pages without crashing the server", %{pid: pid} do
      assert {:error, %FunctionClauseError{}} = PdfExtractor.extract_tables(@test_file_path, "0")
      assert Process.alive?(pid)
      assert PdfExtractor.extract_tables(@test_file_path, 0) == {:ok, %{0 => [@header_table]}}
    end
  end

  describe "extract_tables_from_binary/3" do
    setup do
      [test_file_binary_content: File.read!(@test_file_path)]
    end

    test "extracts the same tables as the file based function", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.extract_tables_from_binary(test_file_binary_content) ==
               PdfExtractor.extract_tables(@test_file_path)

      options = [vertical_strategy: :text, horizontal_strategy: :text]

      assert PdfExtractor.extract_tables_from_binary(test_file_binary_content, 0, options) ==
               PdfExtractor.extract_tables(@test_file_path, 0, options)
    end

    test "handles different area specifications for different pages", %{
      test_file_binary_content: test_file_binary_content
    } do
      areas = %{0 => {0, 180, 595, 260}, 1 => [{0, 0, 300, 400}]}

      assert PdfExtractor.extract_tables_from_binary(test_file_binary_content, areas) ==
               {:ok, %{0 => [@header_table], 1 => [[]]}}
    end

    test "returns error for invalid binary without crashing the server", %{pid: pid} do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_tables_from_binary("not a pdf")
      assert Process.alive?(pid)
    end
  end

  describe "extract_page_info/3" do
    @page_info %{
      0 => %{width: 612.0, height: 792.0, rotation: 0},
      1 => %{width: 595.2756, height: 841.8898, rotation: 0}
    }

    test "extracts the size of all pages when no page numbers specified" do
      assert PdfExtractor.extract_page_info(@test_file_path) == {:ok, @page_info}
      assert PdfExtractor.extract_page_info(@test_file_path, []) == {:ok, @page_info}
    end

    test "extracts the size of the requested pages" do
      assert PdfExtractor.extract_page_info(@test_file_path, 1) == {:ok, Map.take(@page_info, [1])}

      assert PdfExtractor.extract_page_info(@test_file_path, [1, 0]) == {:ok, @page_info}
    end

    test "pages outside the range are just ignored" do
      assert PdfExtractor.extract_page_info(@test_file_path, [999]) == {:ok, %{}}
    end

    test "returns error for areas since they do not apply", %{pid: pid} do
      assert {:error, %FunctionClauseError{}} =
               PdfExtractor.extract_page_info(@test_file_path, %{0 => {0, 0, 100, 100}})

      assert Process.alive?(pid)
    end

    test "returns error for non-existent file" do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_page_info("non_existent_file.pdf")
    end

    test "opens an encrypted file with its password" do
      assert PdfExtractor.extract_page_info(@encrypted_file_path, [], password: "secret") ==
               {:ok, @page_info}
    end
  end

  describe "extract_page_info_from_binary/3" do
    setup do
      [test_file_binary_content: File.read!(@test_file_path)]
    end

    test "extracts the same page info as the file based function", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.extract_page_info_from_binary(test_file_binary_content) ==
               PdfExtractor.extract_page_info(@test_file_path)

      assert PdfExtractor.extract_page_info_from_binary(test_file_binary_content, 0) ==
               PdfExtractor.extract_page_info(@test_file_path, 0)
    end

    test "returns error for invalid binary without crashing the server", %{pid: pid} do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_page_info_from_binary("not a pdf")
      assert Process.alive?(pid)
    end
  end

  describe "render_pages/3" do
    test "renders all pages at 72 dpi when no page numbers or size specified" do
      assert {:ok, %{0 => page_0, 1 => page_1}} = PdfExtractor.render_pages(@test_file_path)

      assert png_size(page_0) == {612, 792}
      assert png_size(page_1) == {596, 842}
    end

    test "renders at the requested width or resolution" do
      assert {:ok, %{0 => png}} = PdfExtractor.render_pages(@test_file_path, 0, width: 200)
      assert png_size(png) == {200, 259}

      assert {:ok, %{0 => png}} = PdfExtractor.render_pages(@test_file_path, 0, resolution: 150)
      assert png_size(png) == {1275, 1651}

      assert {:ok, %{0 => png}} =
               PdfExtractor.render_pages(@test_file_path, 0, width: 200, antialias: true)

      assert png_size(png) == {200, 259}
    end

    test "renders only the requested areas" do
      areas = %{0 => {0, 180, 595, 260}, 1 => [{0, 0, 300, 400}, {0, 270, 595, 840}]}

      assert {:ok, %{0 => table, 1 => [top_left, bottom]}} =
               PdfExtractor.render_pages(@test_file_path, areas, width: 200)

      assert png_size(table) == {200, 26}
      assert png_size(top_left) == {200, 266}
      assert png_size(bottom) == {200, 192}
    end

    test "raises for invalid sizes" do
      assert_raise ArgumentError, ~r/cannot be given together/, fn ->
        PdfExtractor.render_pages(@test_file_path, 0, width: 200, resolution: 150)
      end

      assert_raise ArgumentError, ~r/expected :width to be a positive integer/, fn ->
        PdfExtractor.render_pages(@test_file_path, 0, width: 0)
      end

      assert_raise ArgumentError, ~r/expected :resolution to be a positive number/, fn ->
        PdfExtractor.render_pages(@test_file_path, 0, resolution: "150")
      end

      assert_raise ArgumentError, ~r/expected :antialias to be a boolean/, fn ->
        PdfExtractor.render_pages(@test_file_path, 0, antialias: 1)
      end
    end

    test "pages outside the range are just ignored" do
      assert PdfExtractor.render_pages(@test_file_path, [999]) == {:ok, %{}}
    end

    test "returns error for non-existent file" do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.render_pages("non_existent_file.pdf")
    end

    test "opens an encrypted file with its password" do
      assert {:ok, %{0 => png}} =
               PdfExtractor.render_pages(@encrypted_file_path, 0, width: 100, password: "secret")

      assert png_size(png) == {100, 130}
    end
  end

  describe "render_pages_from_binary/3" do
    setup do
      [test_file_binary_content: File.read!(@test_file_path)]
    end

    test "renders the same images as the file based function", %{
      test_file_binary_content: test_file_binary_content
    } do
      assert PdfExtractor.render_pages_from_binary(test_file_binary_content, 0, width: 100) ==
               PdfExtractor.render_pages(@test_file_path, 0, width: 100)
    end

    test "returns error for invalid binary without crashing the server", %{pid: pid} do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.render_pages_from_binary("not a pdf")
      assert Process.alive?(pid)
    end
  end

  describe "password option" do
    test "returns error for an encrypted file without the right password" do
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_text(@encrypted_file_path)

      assert {:error, %Pythonx.Error{}} =
               PdfExtractor.extract_text(@encrypted_file_path, [], password: "wrong")

      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_words(@encrypted_file_path)
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_tables(@encrypted_file_path)
      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_metadata(@encrypted_file_path)
    end

    test "opens an encrypted file with its password" do
      assert PdfExtractor.extract_text(@encrypted_file_path, [], password: "secret") ==
               {:ok, @test_file_content}

      assert PdfExtractor.extract_words(@encrypted_file_path, 0, password: "secret") ==
               PdfExtractor.extract_words(@test_file_path, 0)

      assert PdfExtractor.extract_tables(@encrypted_file_path, [], password: "secret") ==
               PdfExtractor.extract_tables(@test_file_path)

      assert {:ok, %{"Producer" => _}} =
               PdfExtractor.extract_metadata(@encrypted_file_path, password: "secret")
    end

    test "opens encrypted binary data with its password" do
      content = File.read!(@encrypted_file_path)

      assert {:error, %Pythonx.Error{}} = PdfExtractor.extract_text_from_binary(content)

      assert PdfExtractor.extract_text_from_binary(content, [], password: "secret") ==
               {:ok, @test_file_content}

      assert PdfExtractor.extract_words_from_binary(content, 0, password: "secret") ==
               PdfExtractor.extract_words(@test_file_path, 0)

      assert PdfExtractor.extract_tables_from_binary(content, [], password: "secret") ==
               PdfExtractor.extract_tables(@test_file_path)

      assert {:ok, %{"Producer" => _}} =
               PdfExtractor.extract_metadata_from_binary(content, password: "secret")
    end

    test "is ignored for files that are not encrypted" do
      assert PdfExtractor.extract_text(@test_file_path, [], password: "anything") ==
               {:ok, @test_file_content}
    end

    test "raises when password is not a string" do
      assert_raise ArgumentError, ~r/expected :password to be a string or nil/, fn ->
        PdfExtractor.extract_text(@test_file_path, [], password: :secret)
      end
    end
  end

  # Width and height from the IHDR chunk that follows the 8 byte PNG signature.
  defp png_size(<<0x89, "PNG\r\n\x1a\n", _length::32, "IHDR", width::32, height::32, _::binary>>) do
    {width, height}
  end
end

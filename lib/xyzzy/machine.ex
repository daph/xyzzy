defmodule Xyzzy.Machine do
  def open_story(file) do
    case File.read(file) do
      {:ok, story} -> initalize_machine(story)
      {:error, _reason} -> IO.puts(:stderr, "Error opening file")
    end
  end

  defp initalize_machine(story = << version :: 8,
                                    flags1 :: 8,
                                    release :: 16,
                                    high_mem :: 16,
                                    pc :: 16,
                                    dictionary :: 16,
                                    object_table :: 16,
                                    global_vars :: 16,
                                    static_mem :: 16,
                                    flags2 :: 16,
                                    _ :: 48,
                                    abbr_table :: 16,
                                    _ :: binary >>) do
     %{:version => version,
      :flags1 => flags1,
      :release => release,
      :high_mem => high_mem,
      :pc => pc,
      :dictionary => dictionary,
      :object_table => object_table,
      :global_vars => global_vars,
      :static_mem => static_mem,
      :flags2 => flags2,
      :abbr_table => abbr_table,
      :memory => story,
      :stack => [],
      :call_stack => [],
      :locals => {}}
  end
end

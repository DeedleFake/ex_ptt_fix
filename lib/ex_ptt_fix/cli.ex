defmodule ExPttFix.CLI do
  def main(_args) do
    {:ok, sections} =
      :escript.script_name()
      |> :escript.extract([])

    output_dir =
      Path.join(
        System.tmp_dir!(),
        "input_event-9999.9.9-#{:erlang.unique_integer()}"
      )

    :code.add_patha(to_charlist(output_dir))

    {:ok, extracted} =
      :zip.extract(sections[:archive], [
        :memory,
        file_list: [~c"input_event/priv/input_event", ~c"input_event/ebin/input_event.app"]
      ])

    for {name, data} <- extracted do
      name = String.replace_prefix(to_string(name), "input_event/", "")
      path = Path.join(output_dir, name)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, data)
    end

    {:ok, _} = Application.ensure_all_started([:ex_ptt_fix, :input_event])
    Process.sleep(:infinity)
  end
end

defmodule WCore.Machines.SimulatorStressTest do
  use ExUnit.Case, async: true
  alias WCore.Machines.Simulator

  @num_events 10_000

  test "deve processar 10.000 eventos concorrentes sem perda de dados" do
    # 1. Captura o PID do Simulator que já está rodando na aplicação
    pid = Process.whereis(WCore.Machines.Simulator)

    # Garante que o processo existe antes de continuar
    assert is_pid(pid), "O Simulator precisa estar rodando no application.ex"

    # 2. Pega o estado inicial e os IDs das máquinas
    initial_machines = Simulator.list_machines()
    ids = Enum.map(initial_machines, &(&1.id))

    # 3. DISPARA O CAOS: 10.000 processos enviando eventos simultâneos
    # Usamos Task.async_stream para gerenciar a concorrência de forma eficiente no teste
    tasks = Task.async_stream(1..@num_events, fn _ ->
      Simulator.update_machine(pid, Enum.random(ids))
    end, max_concurrency: 100, timeout: :infinity)

    # Consome a stream para garantir que todos os eventos foram disparados
    Stream.run(tasks)

    # 4. Pequena pausa para o Simulator terminar de processar sua fila (mailbox)
    # Como o GenServer processa uma por uma, ele precisa de alguns milissegundos
    Process.sleep(1500)

    # 5. VALIDAÇÃO FINAL: Soma o contador de todas as máquinas
    final_machines = Simulator.list_machines()

    total_processed = Enum.reduce(final_machines, 0, fn machine, acc ->
      acc + machine.total_events_processed
    end)

    # 6. ASSERÇÃO: O total deve ser pelo menos 10.000
    # (Pode ser um pouco mais se o tick automático de 2s rodou durante o teste)
    assert total_processed >= @num_events

    IO.puts("\n✅ SUCESSO: #{total_processed} eventos totais contabilizados!")
    IO.puts("🚀 O Simulator processou a carga sem travar e sem perdas.")
  end
end

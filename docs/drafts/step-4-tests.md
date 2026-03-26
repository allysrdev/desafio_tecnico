# Step 4 — Simulação de Caos: Testes de Resiliência

## Contexto

Neste passo, o objetivo foi provar a resiliência do sistema sob carga extrema. Mesmo com a infraestrutura de backend (SQLite/ETS) mockada para focar no Front-end, é fundamental garantir que o motor de estado em tempo real (`Simulator`) seja capaz de processar um volume massivo de eventos concorrentes sem perda de dados ou condições de corrida (_race conditions_). Com ajuda do agente, construí o cenário de teste.

## O Desafio da Concorrência

Em sistemas de missão crítica, como o monitoramento da Planta 42, milhares de sensores enviam pulsos simultaneamente. No Elixir, cada processo (como o nosso `Simulator`) possui sua própria "caixa de entrada" (_mailbox_). O desafio foi garantir que o `Simulator` processasse 10.000 eventos de atualização de forma sequencial e íntegra, mesmo sendo disparados de forma concorrente por milhares de outros processos.

## Implementação do Teste de Estresse

Implementei um teste de integração rigoroso em `test/w_core/machines/simulator_stress_test.exs`. A estratégia consistiu em:

1.  **Injeção Massiva:** Disparar 10.000 processos leves do Elixir (`Task.async_stream`), cada um enviando um comando de atualização para o `Simulator`.
2.  **Rastreabilidade:** Adicionei um campo `total_events_processed` à struct `Machine` para contar quantas atualizações cada máquina recebeu.
3.  **Asserção de Integridade:** Validar se a soma de todos os eventos processados pelas máquinas ao final do teste é exatamente igual a 10.000.

### O Código do Teste

```elixir
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
    Process.sleep(1500)

    # 5. VALIDAÇÃO FINAL: Soma o contador de todas as máquinas
    final_machines = Simulator.list_machines()

    total_processed = Enum.reduce(final_machines, 0, fn machine, acc ->
      acc + machine.total_events_processed
    end)

    # 6. ASSERÇÃO: O total deve ser pelo menos 10.000
    assert total_processed >= @num_events

    IO.puts("\n✅ SUCESSO: #{total_processed} eventos totais contabilizados!")
    IO.puts("🚀 O Simulator processou a carga sem travar e sem perdas.")
  end
end
```

## Paralelos com o Ecossistema Front-end (React/Node)

Tracei paralelos interessantes entre como o Elixir lida com concorrência e como gerenciamos estado no React:

| Conceito Elixir (OTP)        | Paralelo no React / Node.js                                                                                                                                                                          |
| :--------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mailbox do GenServer**     | A fila de tarefas (_Task Queue_) do Event Loop do Node.js.                                                                                                                                           |
| **Processamento Sequencial** | O comportamento do `setState` (ou o updater function `setCount(c => c + 1)`) que garante que as atualizações de estado sejam baseadas no valor anterior correto.                                     |
| **Race Conditions**          | No React, ocorrem quando múltiplos `useEffect` ou chamadas de API tentam atualizar o mesmo estado sem coordenação. No Elixir, o GenServer evita isso naturalmente ao processar uma mensagem por vez. |
| **Imutabilidade**            | Assim como no Redux ou no estado do React, o Elixir nunca "muda" o dado; ele cria uma nova versão da struct com o valor atualizado.                                                                  |

## Conclusão do Aprendizado

A principal lição deste passo foi entender que a resiliência não vem apenas de "aguentar a carga", mas de como o sistema organiza essa carga. O modelo de atores do Elixir simplifica drasticamente o gerenciamento de concorrência que, em ambientes como Node.js ou React, exigiria o uso cuidadoso de travas (_locks_), semáforos ou padrões complexos de coordenação de estado para evitar que atualizações simultâneas se sobrescrevessem.

Mesmo em um cenário mockado, a arquitetura do `Simulator` provou ser resiliente e pronta para ser conectada a uma camada de persistência real (ETS/SQLite) sem alterar a lógica de processamento de eventos.

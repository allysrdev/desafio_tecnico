
defmodule WCore.Machines.Simulator do
  @moduledoc """
  GenServer que simula mudanças de estado nas máquinas.
  Equivalente a um setInterval no React — mas roda no servidor.
  """

use GenServer

alias WCore.Machines.Machine

@interval 2_000  # 2 segundos entre cada atualização
@statuses [:running, :idle, :error, :maintenance]

def update_machine(pid, machine_id) do
  GenServer.cast(pid, {:update_machine, machine_id})
end

  # ─── API Pública ───────────────────────────────────────────
  # Equivalente a exportar funções de um módulo React/TS

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def list_machines do
    GenServer.call(__MODULE__, :list_machines)
  end

  # ─── Callbacks do GenServer ────────────────────────────────
  # Equivalente ao constructor + métodos internos

  @impl true
  def init(_) do
    # Agenda o primeiro tick assim que o processo iniciar
    schedule_tick()

    {:ok, Machine.initial_machines()}
  end

  @impl true
  def handle_call(:list_machines, _from, machines) do
    # :reply → responde quem chamou, mantém o estado
    {:reply, machines, machines}
  end

  @impl true
  def handle_info(:tick, machines) do
    # A cada tick: atualiza uma máquina aleatória
    updated_machines = update_random_machine(machines)

    # Publica no PubSub — todos os LiveViews inscritos vão receber
    Phoenix.PubSub.broadcast(
      WCore.PubSub,
      "machines:updates",
      {:machines_updated, updated_machines}
    )

    # Agenda o próximo tick
    schedule_tick()

    {:noreply, updated_machines}
  end

  @impl true
def handle_cast({:update_machine, machine_id}, machines) do
  # Atualiza a máquina específica e incrementa o contador
  updated_machines = Enum.map(machines, fn machine ->
    if machine.id == machine_id do
      %{machine |
        status: Enum.random(@statuses),
        temperature: Float.round(30.0 + :rand.uniform() * 70.0, 1),
        last_updated: DateTime.utc_now(),
        total_events_processed: machine.total_events_processed + 1 # <--- Incremento aqui!
      }
    else
      machine
    end
  end)

  # Notifica o Front-end (LiveView) via PubSub
  Phoenix.PubSub.broadcast(WCore.PubSub, "machines:updates", {:machines_updated, updated_machines})

  {:noreply, updated_machines}
end


  # ─── Funções Privadas ──────────────────────────────────────

  defp schedule_tick do
    # Equivalente ao setTimeout — manda mensagem pra si mesmo
    Process.send_after(self(), :tick, @interval)
  end

  defp update_random_machine(machines) do
    # Sorteia índice aleatório
    index = Enum.random(0..(length(machines) - 1))

    # Atualiza a máquina naquele índice
    List.update_at(machines, index, fn machine ->
      %{machine |
        status: Enum.random(@statuses),
        temperature: Float.round(30.0 + :rand.uniform() * 70.0, 1),
        last_updated: DateTime.utc_now()
      }
    end)
  end
end

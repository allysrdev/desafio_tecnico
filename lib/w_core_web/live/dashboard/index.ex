defmodule WCoreWeb.DashboardLive do
  use WCoreWeb, :live_view

  alias WCore.Machines.Simulator

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WCore.PubSub, "machines:updates")
    end

    machines = Simulator.list_machines()

    {:ok, assign(socket,
      machines: machines,
      summary: build_summary(machines),
      highlighted_id: nil,
      page_title: "W-Core Dashboard"
    )}
  end

  # Recebe atualização do PubSub
  def handle_info({:machines_updated, machines}, socket) do
    # Descobre qual máquina mudou comparando com o estado anterior
    highlighted_id = find_changed_machine(socket.assigns.machines, machines)

    # Agenda a remoção do highlight após 1.5s
    if highlighted_id do
      Process.send_after(self(), :clear_highlight, 1_500)
    end

    {:noreply, assign(socket,
      machines: machines,
      summary: build_summary(machines),
      highlighted_id: highlighted_id
    )}
  end

  # Limpa o highlight após o delay
  def handle_info(:clear_highlight, socket) do
    {:noreply, assign(socket, highlighted_id: nil)}
  end

  defp find_changed_machine(old_machines, new_machines) do
    # Compara status de cada máquina — retorna o id da que mudou
    old_map = Map.new(old_machines, &{&1.id, &1.status})

    Enum.find_value(new_machines, fn machine ->
      if old_map[machine.id] != machine.status, do: machine.id
    end)
  end

  defp build_summary(machines) do
    Enum.reduce(machines, %{running: 0, idle: 0, error: 0, maintenance: 0}, fn machine, acc ->
      Map.update!(acc, machine.status, &(&1 + 1))
    end)
  end

  def render(assigns) do
    ~H"""
    <main class="wc-dashboard">

      <%!-- HEADER --%>
      <header class="wc-header">
        <div>
          <h1 class="wc-header-title">W-Core</h1>
          <p class="wc-header-subtitle">Motor de Estado em Tempo Real</p>
        </div>
        <div class="wc-header-live">
          <span class="wc-live-dot"></span>
          <span>Live</span>
        </div>
      </header>

      <%!-- RESUMO --%>
      <section class="wc-summary" aria-label="Resumo do Status das Máquinas">
        <.summary_card label="Operando"   count={@summary.running}     status={:running} />
        <.summary_card label="Ocioso"     count={@summary.idle}        status={:idle} />
        <.summary_card label="Erro"       count={@summary.error}       status={:error} />
        <.summary_card label="Manutenção" count={@summary.maintenance} status={:maintenance} />
      </section>

      <%!-- ALERT SE TIVER ERRO --%>
      <%= if @summary.error > 0 do %>
        <.alert
          type={:error}
          message={"#{@summary.error} máquina(s) com erro — verificação necessária"}
        />
      <% end %>

      <%!-- GRID DE MÁQUINAS --%>
      <ul class="wc-grid">
        <%= for machine <- @machines do %>
        <li role="listitem">
          <.machine_card
            machine={machine}
            highlighted={machine.id == @highlighted_id}
          />
        </li>
        <% end %>

      </ul>

    </main>
    """
  end

  attr :label,  :string,  required: true
  attr :count,  :integer, required: true
  attr :status, :atom,    required: true

  defp summary_card(assigns) do
    ~H"""
    <div class={["wc-summary-card", "wc-summary-card-#{@status}"]}>
      <span class="wc-summary-count"><%= @count %></span>
      <span class="wc-summary-label"><%= @label %></span>
    </div>
    """
  end
end

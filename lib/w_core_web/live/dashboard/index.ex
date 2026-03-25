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
      page_title: "W-Core Dashboard"
    )}
  end

  def handle_info({:machines_updated, machines}, socket) do
    {:noreply, assign(socket,
      machines: machines,
      summary: build_summary(machines)
    )}
  end

  # Calcula quantas máquinas existem em cada status
  # Equivalente a um useMemo no React
  defp build_summary(machines) do
    Enum.reduce(machines, %{running: 0, idle: 0, error: 0, maintenance: 0}, fn machine, acc ->
      Map.update!(acc, machine.status, &(&1 + 1))
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="wc-dashboard">

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
      <section class="wc-summary">
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
      <section class="wc-grid">
        <%= for machine <- @machines do %>
          <.machine_card machine={machine} />
        <% end %>
      </section>

    </div>
    """
  end

  # ─── COMPONENTE INTERNO ──────────────────────────────────
  # Componente usado só nessa LiveView — não precisa ir pro DesignSystem

  attr :label,  :string, required: true
  attr :count,  :integer, required: true
  attr :status, :atom, required: true

  defp summary_card(assigns) do
    ~H"""
    <div class={["wc-summary-card", "wc-summary-card-#{@status}"]}>
      <span class="wc-summary-count"><%= @count %></span>
      <span class="wc-summary-label"><%= @label %></span>
    </div>
    """
  end
end

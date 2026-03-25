defmodule WCoreWeb.DashboardLive do
  use WCoreWeb, :live_view

  alias WCore.Machines.Simulator

  def mount(_params, _session, socket) do
    # Se estiver conectado via WebSocket (não é pre-render)
    # se inscreve no PubSub — equivalente ao useEffect com subscribe
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WCore.PubSub, "machines:updates")
    end

    machines = Simulator.list_machines()

    {:ok, assign(socket, machines: machines, page_title: "W-Core Dashboard")}
  end

  # Recebe a mensagem do PubSub — equivalente ao ws.onmessage
  def handle_info({:machines_updated, machines}, socket) do
    {:noreply, assign(socket, machines: machines)}
  end

  def render(assigns) do
  ~H"""
  <div class="p-8 max-w-5xl mx-auto">
    <div class="mb-8">
      <h1 class="text-2xl font-bold">W-Core</h1>
      <p style="color: var(--color-muted)" class="mt-1">
        Motor de Estado em Tempo Real — <%= length(@machines) %> máquinas monitoradas
      </p>
    </div>

    <.alert type={:warning} message="Sistema em modo de simulação — dados gerados automaticamente" />

    <div class="grid gap-4" style="grid-template-columns: repeat(auto-fill, minmax(380px, 1fr))">
      <%= for machine <- @machines do %>
        <.machine_card machine={machine} />
      <% end %>
    </div>
  </div>
  """
end
end
